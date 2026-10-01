use clap::Parser;
use indicatif::{MultiProgress, ProgressBar, ProgressStyle};
use num_cpus;
use std::path::{Path, PathBuf};
use std::sync::Arc;
use tokio::fs;
use tokio::sync::Semaphore;

#[derive(Parser, Debug)]
#[command(name = "bulk_pic_resizer")]
#[command(about = "Resize images in batch with maximum PNG optimization", long_about = None)]
struct Args {
    /// Size in format WIDTHxHEIGHT (e.g., 800x600)
    #[arg(long, required = true)]
    size: String,

    /// Output directory (optional; defaults to input file's directory)
    #[arg(long)]
    output_dir: Option<PathBuf>,

    /// Output format extension (optional; defaults to input format)
    #[arg(long)]
    format: Option<String>,

    /// Input files
    #[arg(value_name = "FILES")]
    files: Vec<PathBuf>,
}

#[derive(Debug, Clone)]
struct Config {
    width: u32,
    height: u32,
    output_dir: Option<PathBuf>,
    format: Option<String>,
}

#[tokio::main]
async fn main() {
    let args = Args::parse();

    // Parse size
    let (width, height) = match parse_size(&args.size) {
        Ok((w, h)) => (w, h),
        Err(e) => {
            eprintln!("Error parsing --size: {}", e);
            std::process::exit(1);
        }
    };

    let config = Config {
        width,
        height,
        output_dir: args.output_dir,
        format: args.format,
    };

    if args.files.is_empty() {
        eprintln!("No input files provided");
        std::process::exit(1);
    }

    // Multi-threading setup
    let max_workers = (num_cpus::get() - 1).max(1);
    let semaphore = Arc::new(Semaphore::new(max_workers));
    let m = MultiProgress::new();

    let mut tasks = vec![];

    for file_path in args.files {
        let config = config.clone();
        let sem = Arc::clone(&semaphore);
        let m = m.clone();

        let task = tokio::spawn(async move {
            let _permit = sem.acquire().await.unwrap();

            let pb = m.add(ProgressBar::new_spinner());
            pb.set_style(
                ProgressStyle::default_spinner()
                    .template("{spinner} {msg}")
                    .unwrap(),
            );
            pb.set_message(format!(
                "Processing: {}",
                file_path.display()
            ));

            if let Err(e) = process_file(&file_path, &config).await {
                eprintln!(
                    "Error processing {}: {}",
                    file_path.display(),
                    e
                );
            }

            pb.finish_with_message(format!(
                "✓ {}",
                file_path.display()
            ));
        });

        tasks.push(task);
    }

    for task in tasks {
        let _ = task.await;
    }
}

fn parse_size(size_str: &str) -> Result<(u32, u32), String> {
    let parts: Vec<&str> = size_str.split('x').collect();
    if parts.len() != 2 {
        return Err(
            "Size must be in format WIDTHxHEIGHT".to_string()
        );
    }
    let width: u32 =
        parts[0].parse().map_err(|_| "Invalid width")?;
    let height: u32 =
        parts[1].parse().map_err(|_| "Invalid height")?;
    Ok((width, height))
}

async fn process_file(
    input_path: &Path,
    config: &Config,
) -> Result<(), Box<dyn std::error::Error>> {
    // Check if file exists and is a file
    if !input_path.is_file() {
        return Err(format!(
            "{} is not a file",
            input_path.display()
        )
            .into());
    }

    // Load image
    let img = image::open(input_path)?;
    let resized = img.resize_exact(
        config.width,
        config.height,
        image::imageops::FilterType::Lanczos3,
    );

    // Determine output path
    let output_dir = if let Some(ref dir) = config.output_dir {
        if dir.is_absolute() {
            dir.clone()
        } else {
            input_path.parent().unwrap_or(Path::new(".")).join(dir)
        }
    } else {
        input_path.parent().unwrap_or(Path::new(".")).to_path_buf()
    };

    fs::create_dir_all(&output_dir).await?;

    let ext = config.format.as_deref().unwrap_or_else(|| {
        input_path
            .extension()
            .and_then(|s| s.to_str())
            .unwrap_or("png")
    });

    let stem =
        input_path.file_stem().unwrap_or_default().to_string_lossy();
    let mut output_path =
        output_dir.join(format!("{}.{}", stem, ext));

    // Handle filename collision
    let mut counter = 1;
    while output_path.exists() {
        output_path =
            output_dir.join(format!("{}_{}.{}", stem, counter, ext));
        counter += 1;
    }

    // Always encode as PNG for maximum optimization
    let rgba_img = resized.to_rgba8();
    let mut png_data = Vec::new();
    {
        let mut encoder = png::Encoder::new(
            &mut png_data,
            config.width,
            config.height,
        );
        encoder.set_color(png::ColorType::Rgba);
        encoder.set_depth(png::BitDepth::Eight);
        encoder.write_header()?.write_image_data(&rgba_img)?;
    }

    let mut options = oxipng::Options::default();
    options.force = true;
    options.interlace = None;
    options.fix_errors = true;
    options.optimize_alpha = true;
    options.fix_errors = true;
    options.color_type_reduction = true;
    options.bit_depth_reduction = true;
    options.palette_reduction = true;
    options.grayscale_reduction = true;
    options.idat_recoding = true;

    let optimized =
        oxipng::optimize_from_memory(&png_data, &options)?;

    // Write to disk
    fs::write(&output_path, optimized).await?;

    Ok(())
}

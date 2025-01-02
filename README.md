# bcl-convert-service

## Overview
The `bcl-convert-service` project is designed to automate the conversion of BCL files to FASTQ files using the `bcl-convert` tool. It also includes functionality to send email notifications about the status of the conversion process.

## Features
- Automated BCL to FASTQ conversion
- Email notifications for process status
- Configurable via environment variables
- Dockerized for easy deployment
- Automatically detects and processes subfolder projects in the `RUNFOLDER_PATH`
- Converts BCL files only if certain conditions are met

## Prerequisites
- Docker
- Docker Compose

## Setup

### Step 1: Clone the Repository
```sh
git clone https://github.com/yourusername/bcl-convert-service.git
cd bcl-convert-service
```

### Step 2: Download the `bcl-convert` RPM
Download the `bcl-convert` RPM for CentOS from the Illumina website and place it in the same directory as the `Dockerfile`. Ensure the RPM file name matches the one given in the  `Dockerfile` file.

### Step 3: Create the `.env` File
Create a `.env` file in the root directory of the project with the following content:

```dotenv
SMTP_SERVER=smtp.example.com
SMTP_PORT=465
SMTP_USER=your-email@example.com
SMTP_FROM=your-email@example.com
SMTP_PASS=your-email-password
RUNFOLDER_PATH=/path/to/runfolder
SAMPLESHEET_PATH=/path/to/samplesheets
TARGETFOLDER_PATH=/path/to/target
LOG_PATH=./logs
MAIL_RECIPIENTS=recipient1@example.com,recipient2@example.com
BCL_CONVERT_PARAMS=--strict-mode true --force --bcl-only-matched-reads true --bcl-sampleproject-subdirectories true
```

### Step 4: Build and Run the Docker Container
Use Docker Compose to build and run the container:

```sh
docker-compose up --build
```

This command will build the Docker image and start the `bcl-convert-service` container. The `process_ngs_runs.sh` script will be executed inside the container, processing the BCL files and sending email notifications as configured.

## Usage
The service will automatically process the BCL files located in the `RUNFOLDER_PATH` and convert them to FASTQ files. The results will be stored in the `TARGETFOLDER_PATH`, and logs will be available in the `LOG_PATH`.

The script detects all subfolder projects in the `RUNFOLDER_PATH` and only converts them if the following conditions are met:
- A sample sheet file exists in the `SAMPLESHEET_PATH`
- The `CopyComplete.txt` and `RTAComplete.txt` files are present in the run folder
- The `FastqComplete.txt` file does not already exist in the output folder

You can run this service periodically using a cron job. For example, you can add the following line to your crontab to run the service every hour:

```sh
0 * * * * cd /path/to/bcl-convert-service && docker-compose run --rm bcl-convert-service
```

## Troubleshooting
- Ensure all environment variables in the `.env` file are correctly set.
- Check the logs in the `LOG_PATH` directory for any errors or issues.

## License
This project is licensed under the MIT License. See the `LICENSE` file for more details.
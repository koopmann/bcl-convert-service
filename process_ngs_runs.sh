#!/bin/bash

RUNFOLDER_PATH="/mnt/run"
SAMPLESHEET_PATH="/mnt/samplesheets"
OUTPUTFOLDER_PATH_PREFIX="/mnt/run"
OUTPUTFOLDER_PATH_SUBDIR="/Data/Intensities/BaseCalls"
TARGETFOLDER_PATH="/mnt/target"
LOG_PATH="/var/log/bcl-convert"
SMTP_SERVER=${SMTP_SERVER}
SMTP_PORT=${SMTP_PORT}
SMTP_USER=${SMTP_USER}
SMTP_PASS=${SMTP_PASS}
MAIL_RECIPIENTS=${MAIL_RECIPIENTS:-"default@example.com"}  # Set a default recipient if not provided


sendMail() {
  local subject=$1
  local body=$2

  if [ -z "$MAIL_RECIPIENTS" ] || [ -z "$subject" ]; then
    echo "Missing environment variables: mail_recipients or subject"
    return 1
  fi

  echo "Sending email with subject: ${subject}"
  echo "Email body: ${body}"

  # Call the Python script to send the email
  python3 /usr/local/bin/send_email.py "${subject}" "${body}"

  if [ $? -eq 0 ]; then
    echo "Email sent successfully."
  else
    echo "Failed to send email."
  fi
}

process_ngs_runs() {
  echo "Starting NGS run processing..."
  for runfolder in "$RUNFOLDER_PATH"/*; do
    if [ -d "$runfolder" ]; then
      runname=$(basename "$runfolder")
      sample_sheet_full_path="$SAMPLESHEET_PATH/${runname}_SampleSheet.csv"
      outputfolder_run_path="$OUTPUTFOLDER_PATH_PREFIX/${runname}"
      outputfolder_run_path_subdir="${outputfolder_run_path}$OUTPUTFOLDER_PATH_SUBDIR"

      targetfolder_run_path="$TARGETFOLDER_PATH/${runname}"
      targetfolder_run_path_subdir="${targetfolder_run_path}$OUTPUTFOLDER_PATH_SUBDIR"

      echo "Processing folder: $runfolder"
      echo "Run name: $runname"
      echo "Sample sheet path: $sample_sheet_full_path"
      echo "Output folder path: $outputfolder_run_path_subdir"

      if [ "$runname" == ".stfolder" ]; then
        echo "Skipping .stfolder"
        continue
      fi

      if [ -f "$sample_sheet_full_path" ]; then
        echo "Sample sheet found: $sample_sheet_full_path"
      else
        echo "Sample sheet missing: $sample_sheet_full_path"
      fi

      if [ -f "$runfolder/CopyComplete.txt" ]; then
        echo "CopyComplete.txt found in $runfolder"
      else
        echo "CopyComplete.txt missing in $runfolder"
      fi

      if [ -f "$runfolder/RTAComplete.txt" ]; then
        echo "RTAComplete.txt found in $runfolder"
      else
        echo "RTAComplete.txt missing in $runfolder"
      fi

      if [ -f "$outputfolder_run_path_subdir/Logs/FastqComplete.txt" ]; then
        echo "FastqComplete.txt already exists in $outputfolder_run_path_subdir"
      else
        echo "FastqComplete.txt missing in $outputfolder_run_path_subdir"
      fi

      if [ -f "$sample_sheet_full_path" ] && [ -f "$runfolder/CopyComplete.txt" ] && [ -f "$runfolder/RTAComplete.txt" ] && [ ! -f "$outputfolder_run_path_subdir/Logs/FastqComplete.txt" ]; then
        already_processed=false
        for file in "$outputfolder_run_path_subdir/"*.fastq.gz; do
          if [ -f "$file" ]; then
            already_processed=true
            echo "Skipped folder because of existing fastq.gz: $file"
            break
          fi
        done

        if [ "$already_processed" = false ]; then
          if [ -z "$(find "$runfolder" -mmin -5)" ]; then
            echo "Start processing folder: $runfolder"
            command="bcl-convert $BCL_CONVERT_PARAMS --bcl-input-directory $runfolder --sample-sheet $sample_sheet_full_path --output-directory $outputfolder_run_path_subdir > $outputfolder_run_path_subdir/bcl2fastq2_output.txt"
            echo "Executing command: $command"
            eval "$command"

            while [ ! -f "$outputfolder_run_path_subdir/Logs/FastqComplete.txt" ]; do
              echo "Waiting for FastqComplete.txt..."
              sleep 120
            done

            mkdir -p "$targetfolder_run_path_subdir"
            echo "Copying from $outputfolder_run_path_subdir to $targetfolder_run_path_subdir"
            cp -rp "$outputfolder_run_path_subdir/"* "$targetfolder_run_path_subdir" && \
            echo "Running rsync..." && \
            rsync -aiu "$runfolder/" "$TARGETFOLDER_PATH/$runname/" >> "$LOG_PATH/preprocess_ngs_rsync.log"
            if [ $? -ne 0 ]; then
              echo "Rsync failed for Run: $runfolder"
              sendMail "Rsync failed for Run: $runfolder" "Lauf: $runfolder"
            fi

            echo "BCL to FASTQ conversion complete for Run: $runfolder"
            sendMail "BCL to FASTQ conversion complete for Run: $runfolder" "Lauf: $runfolder"
          fi
        fi
      else
        echo "Skipped folder because of missing sheet, or not RTAComplete or existing FastqComplete: $runfolder"
      fi

      if [ -f "$sample_sheet_full_path" ] && [ ! -f "$runfolder/RTAComplete.txt" ] && [ -f "$outputfolder_run_path_subdir/Logs/FastqComplete.txt" ]; then
        echo "Removing folder: $runfolder"
        rm -rf "$runfolder"
      fi
    else
      echo "No directories found in $RUNFOLDER_PATH"
    fi
  done
  echo "NGS run processing complete."
}

process_ngs_runs
import os
import smtplib
import logging
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

# Configure logging
logging.basicConfig(level=logging.DEBUG, format='%(asctime)s - %(levelname)s - %(message)s')

def send_mail(subject, body, recipients):
    smtp_server = os.getenv("SMTP_SERVER")
    smtp_port = os.getenv("SMTP_PORT")
    smtp_user = os.getenv("SMTP_USER")
    smtp_pass = os.getenv("SMTP_PASS")
    smtp_from = os.getenv("SMTP_FROM")

    if not recipients or not subject:
        logging.error("Missing environment variables: recipients or subject")
        return

    logging.debug(f"SMTP Server: {smtp_server}")
    logging.debug(f"SMTP Port: {smtp_port}")
    logging.debug(f"SMTP User: {smtp_user}")
    logging.debug(f"Recipients: {recipients}")

    # Create the email
    msg = MIMEMultipart()
    msg['From'] = smtp_from
    msg['To'] = recipients
    msg['Subject'] = subject
    msg.attach(MIMEText(body, 'plain'))

    logging.debug("Email created successfully")

    try:
        # Connect to the SMTP server
        logging.debug("Connecting to SMTP server...")
        server = smtplib.SMTP_SSL(smtp_server, smtp_port)
        server.set_debuglevel(1)  # Enable smtplib debug output
        logging.debug("Logging in to SMTP server...")
        server.login(smtp_user, smtp_pass)
        logging.debug("Sending email...")
        server.sendmail(smtp_user, recipients.split(','), msg.as_string())
        server.quit()
        logging.info("Email sent successfully.")
    except Exception as e:
        logging.error(f"Failed to send email: {e}")

if __name__ == "__main__":
    import sys
    if len(sys.argv) != 3:
        logging.error("Usage: send_email.py <subject> <body>")
        sys.exit(1)
    subject = sys.argv[1]
    body = sys.argv[2]
    recipients = os.getenv("RECIPIENTS")
    send_mail(subject, body, recipients)
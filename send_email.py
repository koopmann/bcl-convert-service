import os
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

def send_mail(subject, body, recipients):
    smtp_server = os.getenv("SMTP_SERVER")
    smtp_port = os.getenv("SMTP_PORT")
    smtp_user = os.getenv("SMTP_USER")
    smtp_pass = os.getenv("SMTP_PASS")

    if not recipients or not subject:
        print("Missing environment variables: recipients or subject")
        return

    print(f"Sending email with subject: {subject}")
    print(f"Email body: {body}")
    print(f"Recipients: {recipients}")

    # Create the email
    msg = MIMEMultipart()
    msg['From'] = smtp_user
    msg['To'] = recipients
    msg['Subject'] = subject
    msg.attach(MIMEText(body, 'plain'))

    try:
        # Connect to the SMTP server
        server = smtplib.SMTP_SSL(smtp_server, smtp_port)
        server.login(smtp_user, smtp_pass)
        server.sendmail(smtp_user, recipients.split(','), msg.as_string())
        server.quit()
        print("Email sent successfully.")
    except Exception as e:
        print(f"Failed to send email: {e}")

if __name__ == "__main__":
    import sys
    if len(sys.argv) != 3:
        print("Usage: send_email.py <subject> <body>")
        sys.exit(1)
    subject = sys.argv[1]
    body = sys.argv[2]
    recipients = os.getenv("RECIPIENTS")
    send_mail(subject, body, recipients)
# main.py
import os
import pickle
from collections import defaultdict
from google_auth_oauthlib.flow import InstalledAppFlow
from google.auth.transport.requests import Request
from googleapiclient.discovery import build
from urllib.parse import quote_plus
import colorama
from colorama import Fore, Style
import socket

# Initialize colorama
colorama.init()

# If modifying these scopes, delete the file token.pickle.
SCOPES = ['https://www.googleapis.com/auth/gmail.readonly']

def authenticate():
    creds = None

    # Check if token.pickle exists
    if os.path.exists('/data/token.pickle'):
        print(f"{Fore.YELLOW}Found existing credentials, attempting to use them...{Style.RESET_ALL}")
        with open('/data/token.pickle', 'rb') as token:
            creds = pickle.load(token)

    # If there are no (valid) credentials available, prompt the user to log in
    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            print(f"{Fore.YELLOW}Refreshing expired credentials...{Style.RESET_ALL}")
            creds.refresh(Request())
        else:
            if not os.path.exists('/data/credentials.json'):
                print(f"{Fore.RED}Error: credentials.json not found. Please make sure you have mounted your data voume correctly.{Style.RESET_ALL}")
                exit(1)

            print(f"{Fore.YELLOW}Starting OAuth authentication flow...{Style.RESET_ALL}")
            port = 8080
            print(f"{Fore.CYAN}Using port {port} for OAuth callback server{Style.RESET_ALL}")

            flow = InstalledAppFlow.from_client_secrets_file(
                '/data/credentials.json',
                SCOPES,
                redirect_uri=f'http://localhost:{port}'
            )

            print(f"{Fore.GREEN}Please check your web browser. If no browser opened automatically, please manually visit the URL that will be displayed.{Style.RESET_ALL}")
            creds = flow.run_local_server(
                port=port,
                prompt='consent',
                success_message='Authentication successful! You may close this window and return to the terminal.',
                bind_addr="0.0.0.0",
                open_browser=False,
                #authorization_prompt_message='Please complete the authentication in your browser.'
            )
            print(f"{Fore.GREEN}Authentication successful!{Style.RESET_ALL}")

        # Save the credentials for the next run
        print(f"{Fore.YELLOW}Saving credentials for future use...{Style.RESET_ALL}")
        with open('/data/token.pickle', 'wb') as token:
            pickle.dump(creds, token)

    return creds

def get_domain_from_email(email):
    if '<' in email:
        email = email.split('<')[1].split('>')[0]
    return email.split('@')[1]

def analyze_emails(service):
    print(f"{Fore.YELLOW}Fetching unread messages from inbox...{Style.RESET_ALL}")

    # Get unread messages in inbox
    results = service.users().messages().list(
        userId='me',
        labelIds=['INBOX', 'UNREAD']
    ).execute()

    messages = results.get('messages', [])

    if not messages:
        print(f"{Fore.YELLOW}No unread messages found in inbox.{Style.RESET_ALL}")
        return

    print(f"{Fore.CYAN}Found {len(messages)} unread messages. Analyzing...{Style.RESET_ALL}")

    grouped_emails = defaultdict(lambda: {'count': 0, 'messages': []})

    for i, message in enumerate(messages, 1):
        if i % 10 == 0:  # Progress indicator every 10 messages
            print(f"{Fore.YELLOW}Processed {i}/{len(messages)} messages...{Style.RESET_ALL}")

        msg = service.users().messages().get(
            userId='me',
            id=message['id']
        ).execute()

        headers = msg['payload']['headers']
        from_header = next(
            (header['value'] for header in headers if header['name'].lower() == 'from'),
            'Unknown'
        )

        domain = get_domain_from_email(from_header)
        grouped_emails[domain]['count'] += 1
        grouped_emails[domain]['messages'].append(msg)

    # Sort domains by count
    sorted_domains = sorted(
        grouped_emails.items(),
        key=lambda x: x[1]['count'],
        reverse=True
    )

    # Print results
    print(f"\n{Fore.GREEN}Analysis Results:{Style.RESET_ALL}")
    print(f"{Fore.CYAN}Found emails from {len(sorted_domains)} different domains{Style.RESET_ALL}")

    for domain, data in sorted_domains:
        search_url = f"https://mail.google.com/mail/u/0/?pli=1#search/from:{quote_plus(domain)}+in:unread"
        print(f"\n{Fore.GREEN}From: {domain} ({data['count']}){Style.RESET_ALL}")
        print(f"{Fore.BLUE}{search_url}{Style.RESET_ALL}")

def main():
    print(f"\n{Fore.CYAN}=== Gmail Domain Analyzer ==={Style.RESET_ALL}")
    print(f"{Fore.YELLOW}Starting authentication process...{Style.RESET_ALL}")

    try:
        creds = authenticate()
        service = build('gmail', 'v1', credentials=creds)
        analyze_emails(service)
    except Exception as e:
        print(f"\n{Fore.RED}An error occurred: {str(e)}{Style.RESET_ALL}")
        exit(1)

if __name__ == '__main__':
    main()
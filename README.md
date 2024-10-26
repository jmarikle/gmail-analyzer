# Gmail Domain Analyzer

A Docker-based tool that analyzes unread emails in your Gmail inbox and groups them by domain, providing counts and convenient search links. Perfect for inbox management and understanding your email patterns.

## Quick Start (Without Repository)

If you want to run the analyzer without cloning the repository, you can pull the image directly from Docker Hub:

1. First, complete the Google Cloud Console setup from the Prerequisites section and download your `credentials.json`

2. Create a directory for credentials and token storage:
```bash
mkdir ~/gmail-analyzer-data
```

3. Copy your credentials into this directory:
```bash
cp /path/to/your/credentials.json ~/gmail-analyzer-data/
```

4. Run the image:
```bash
docker run --rm -it \
  -p 8080:8080 \
  -v ~/gmail-analyzer-data:/data \
  jmarikle/gmail-analyzer:latest
```

## Development Note

This project was primarily generated using Claude.ai by Anthropic. Specifically:

- The core Python application code was generated and iteratively refined through conversations with Claude
- The Dockerfile and requirements.txt were generated to create a working containerized environment
- The Makefile was generated with inspiration from an existing template, then enhanced with versioning and credential handling
- This README was generated to provide comprehensive documentation

While the application was AI-generated, all code has been tested and verified to work as described. The OAuth2 implementation and Gmail API integration follow Google's best practices and security requirements.

### Why Disclose AI Usage?

We believe in transparency about AI usage in development. While AI is a powerful tool for code generation and documentation, users should be aware of how their tools are created. This allows for:

- Better understanding of the development process
- Appropriate expectations about support and maintenance
- Awareness of potential AI-related limitations or biases
- Encouragement of open discussion about AI in development

### Human Oversight

While Claude.ai generated most of the code, human oversight was maintained throughout the development process to ensure:
- Security best practices
- Code quality and testing
- Documentation accuracy
- Proper error handling
- OAuth2 implementation security

Feel free to review, use, and modify this code according to your needs. If you have questions or concerns about the AI-generated aspects of this project, please open an issue for discussion.

## Prerequisites

### 1. Google Cloud Console Setup

1. Create a new Google Cloud Project:
   - Go to [Google Cloud Console](https://console.cloud.google.com/)
   - Click "New Project" in the top-right dropdown
   - Name your project (e.g., "Gmail Domain Analyzer")
   - Click "Create"

2. Enable the Gmail API:
   - Select your project
   - Go to the [API Library](https://console.cloud.google.com/apis/library)
   - Search for "Gmail API"
   - Click "Enable"

3. Create OAuth 2.0 Credentials:
   - Go to the [Credentials page](https://console.cloud.google.com/apis/credentials)
   - Click "Create Credentials" → "OAuth client ID"
   - Select "Desktop app" as the application type
   - Name your client (e.g., "Gmail Domain Analyzer Client")
   - Click "Create"
   - Download the credentials (click the download icon)
   - Rename the downloaded file to `credentials.json`

### 2. System Requirements

- Docker installed and running
- Make (usually pre-installed on Linux/Mac, available via various package managers)
- Git (for version control and automatic versioning)

## Installation

1. Clone the repository:
```bash
git clone https://github.com/jmarikle/gmail-analyzer.git
cd gmail-analyzer
```

2. Place your `credentials.json` file in the project directory:
```bash
cp /path/to/downloaded/credentials.json .
```

## Usage

### Basic Usage

1. Build the Docker image:
```bash
make build
```

2. Run the analyzer:
```bash
make run
```

3. Follow the authentication flow:
   - The app will display a URL
   - Open the URL in your browser
   - Sign in with your Google account
   - Grant the requested permissions
   - The analysis will begin automatically

### Example Output

```
=== Gmail Domain Analyzer ===
Starting authentication process...
Found existing credentials, attempting to use them...
Fetching unread messages from inbox...
Found 42 unread messages. Analyzing...
Processed 10/42 messages...
Processed 20/42 messages...
Processed 30/42 messages...
Processed 40/42 messages...

Analysis Results:
Found emails from 15 different domains

From: example.com (12)
https://mail.google.com/mail/u/0/?pli=1#search/from:example.com+in:unread

From: newsletter.com (8)
https://mail.google.com/mail/u/0/?pli=1#search/from:newsletter.com+in:unread

...
```

### Advanced Usage

#### Specify Version During Build
```bash
make build VERSION=1.2.3
```

#### Run Specific Version
```bash
make run VERSION=1.2.3
```

#### Check Current Version
```bash
make version
```

#### Clean Up Images
```bash
make clean
```

## Project Structure

```
gmail-analyzer/
├── data/
│   ├── .gitkeep
│   ├── credentials.json (you need to add this)
│   └── token.pickle (generated during authentication)
├── .dockerignore
├── .gitignore
├── Dockerfile
├── LICENSE.md
├── main.py
├── Makefile
├── README.md
└── requirements.txt
```

## Contributing

### Development Setup

1. Fork the repository
2. Clone your fork:
```bash
git clone https://github.com/yourusername/gmail-analyzer.git
```

3. Make your changes
4. Test locally:
```bash
make build
make run
```

### Building and Pushing Docker Images

1. Update the `DOCKER_HUB_USERNAME` in the Makefile with your Docker Hub username

2. Login to Docker Hub:
```bash
docker login
```

3. Build and push with version tag:
```bash
make push VERSION=1.2.3
```

### Version Management

The project uses Git tags for version management. To create a new version:

1. Create and push a tag:
```bash
git tag v1.2.3
git push origin v1.2.3
```

2. Build and push the Docker image:
```bash
make push
```

## Troubleshooting

### Common Issues

1. **Authentication Failed**
   - Ensure `credentials.json` is in the project directory
   - Check if the OAuth consent screen is properly configured
   - Verify you're using the correct Google account

2. **Docker Build Fails**
   - Ensure Docker is running
   - Check internet connectivity for package downloads
   - Verify Docker has sufficient resources

3. **Permission Issues**
   - Ensure you've granted the necessary Gmail permissions
   - Check if your Google Cloud Project has the Gmail API enabled
   - Verify your OAuth consent screen configuration

### Token Persistence

The application creates a `token.pickle` file to store authentication tokens. This file is:
- Mounted via Docker volume
- Persisted between runs
- Should not be committed to version control

To reset authentication:
```bash
rm token.pickle
```

## Security Notes

- Never commit `credentials.json` or `token.pickle` to version control
- Keep your OAuth client ID and secret confidential
- Regularly review your Google Cloud Console security settings
- Use different credentials for development and production

## License

MIT License - See [LICENSE.md](./LICENSE.md) file for details.

## Support

For issues and feature requests, please:
1. Check existing issues in the GitHub repository
2. Create a new issue with:
   - Clear description
   - Steps to reproduce
   - Expected vs actual behavior
   - System information

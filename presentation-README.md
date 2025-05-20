# E-Commerce Microservices DevOps Pipeline Presentation

This directory contains a presentation about the E-Commerce Microservices DevOps Pipeline project.

## Contents

- `presentation.md` - The Marp-formatted Markdown presentation file
- `generate-presentation.sh` - Script to generate a PDF from the presentation
- `ecommerce-devops-presentation.pdf` - The generated PDF presentation (after running the script)

## Generating the Presentation

To generate the PDF presentation from the Markdown file, you'll need to have [Marp CLI](https://github.com/marp-team/marp-cli) installed.

### Prerequisites

- Node.js and npm
- Marp CLI (`npm install -g @marp-team/marp-cli`)

### Steps

1. Make sure the script is executable:

   ```bash
   chmod +x generate-presentation.sh
   ```

2. Run the script:

   ```bash
   ./generate-presentation.sh
   ```

3. The script will:
   - Check if Marp CLI is installed and install it if needed
   - Generate the PDF presentation
   - Open the PDF if you're on macOS or Linux with a GUI

## Presentation Overview

The presentation covers:

1. Project Requirements
2. Initial Ambitious Plan
3. Initial Architecture Vision
4. Pragmatic Implementation
5. System Architecture
6. CI/CD Pipeline
7. Blue-Green Deployment Strategy
8. Version Management
9. GitHub Actions Workflows
10. Database Management
11. Smoke Testing
12. Key Technical Decisions
13. Lessons Learned
14. Future Enhancements

## Customizing the Presentation

You can edit the `presentation.md` file to customize the content. The presentation uses [Marp](https://marp.app/) directives for formatting.

Some key Marp directives used:

- `---` - Slide separator
- `marp: true` - Enables Marp
- `theme: default` - Sets the theme
- `paginate: true` - Enables page numbers
- `backgroundColor: #fff` - Sets the background color
- `![bg right:40% 80%](image-url)` - Adds a background image to the right side

After making changes, run the `generate-presentation.sh` script again to update the PDF.

#!/bin/bash

# Script to generate a PDF presentation from the Markdown file using Marp CLI
# Make sure you have Marp CLI installed: npm install -g @marp-team/marp-cli

echo "Generating presentation PDF from Markdown..."

# Check if Marp CLI is installed
if ! command -v marp &> /dev/null; then
    echo "Marp CLI is not installed. Installing now..."
    npm install -g @marp-team/marp-cli
fi

# Generate the PDF
marp --pdf presentation.md -o ecommerce-devops-presentation.pdf

# Check if the PDF was generated successfully
if [ -f "ecommerce-devops-presentation.pdf" ]; then
    echo "PDF generated successfully: ecommerce-devops-presentation.pdf"
    
    # Try to open the PDF if on macOS or Linux with a GUI
    if [[ "$OSTYPE" == "darwin"* ]]; then
        open ecommerce-devops-presentation.pdf
    elif [[ "$OSTYPE" == "linux-gnu"* ]] && [ -n "$DISPLAY" ]; then
        xdg-open ecommerce-devops-presentation.pdf
    else
        echo "PDF is ready for viewing."
    fi
else
    echo "Failed to generate PDF. Please check if Marp CLI is installed correctly."
fi
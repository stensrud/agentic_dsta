## Test your agent locally

1.  **Run the FastAPI server locally with python:**

    1.  **Set up environment variables:** Create a `.env` file by copying the
        `.env.example` template:
        ```bash
        cp .env.example .env
        ```
        Then, open the `.env` file and replace the placeholder values with your
        actual credentials.

    2.  **Load environment variables:** After setting up your `.env` file, load the variables into your current shell session by running:

        ```bash
        export $(grep -v '^#' .env | xargs)
        ```

        This command reads the `.env` file, and the `export` command makes them available to any processes you run in that shell.

    3.  **Install dependencies**
        ```bash
        pip install -r requirements.txt
        ```

    3.  **Run the application:** Navigate to the directory containing `main.py`
        and run the script:

        ```bash
        python3 -m agentic_dsta.main
        ```

        This will start the FastAPI server, on `http://0.0.0.0:8080`.

## Security best practices

*   **Dependency pinning:** All dependencies in `requirements.txt` are pinned to specific versions. This mitigates the risk of supply chain attacks and ensures that your deployments are predictable. Regularly update your dependencies to patch known vulnerabilities.
*   **Principle of least privilege:** The `Dockerfile` creates a non-root user to run the application, reducing the potential impact of a container compromise.
*   **CORS:** For production environments, the `ALLOWED_ORIGINS` in `main.py` should be updated to a more restrictive list of trusted domains.
*   **Secret management:** All secrets are managed through Google Cloud Secret Manager, and the `.env` file is included in `.gitignore` to prevent accidental exposure.

**Important:** Never hardcode sensitive credentials. Using environment variables
ensures these are handled more securely.

**WARNING:** Do not commit `.env` files or hardcode secrets in your code.
It is strongly recommended to use a secret management solution like Google Cloud Secret Manager for production environments.

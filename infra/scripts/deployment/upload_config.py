#!/usr/bin/env python3
import argparse
import json
import logging
import os
from google.cloud import firestore
from google.oauth2 import credentials

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

def upload_config(project_id, database, collection_name, document_id, config_path, access_token=None):
    """
    Uploads configuration from a JSON file to Firestore.
    """
    try:
        # Load configuration
        with open(config_path, 'r') as f:
            config_data = json.load(f)

        logger.info(f"Loaded configuration from {config_path}")

        # Initialize Firestore client
        # If access_token is provided, use it for authentication (useful for impersonation)
        if access_token:
             # Create credentials object from access token
            creds = credentials.Credentials(token=access_token)
            db = firestore.Client(project=project_id, database=database, credentials=creds)
            logger.info(f"Initialized Firestore client for project {project_id}, database {database} using provided access token")
        else:
            db = firestore.Client(project=project_id, database=database)
            logger.info(f"Initialized Firestore client for project {project_id}, database {database} using default credentials")

        # Get the document reference
        doc_ref = db.collection(collection_name).document(document_id)

        # Upload data
        doc_ref.set(config_data)
        logger.info(f"Successfully uploaded configuration to {collection_name}/{document_id}")

    except Exception as e:
        logger.error(f"Failed to upload configuration: {e}")
        raise

def _upload_data(project_id, database, collection_name, document_id, data, access_token=None):
    """
    Helper to upload dictionary data directly.
    """
    try:
        if access_token:
            creds = credentials.Credentials(token=access_token)
            db = firestore.Client(project=project_id, database=database, credentials=creds)
        else:
            db = firestore.Client(project=project_id, database=database)

        doc_ref = db.collection(collection_name).document(str(document_id))
        doc_ref.set(data)
        logger.info(f"Successfully uploaded batch item to {collection_name}/{document_id}")
    except Exception as e:
        logger.error(f"Failed to upload batch item {collection_name}/{document_id}: {e}")
        raise

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Upload Google Ads configuration to Firestore.")
    parser.add_argument("--project_id", required=True, help="Google Cloud Project ID")
    parser.add_argument("--database", required=True, help="Firestore Database Name")
    parser.add_argument("--collection_name", default="GoogleAdsConfig", help="Firestore Collection Name")
    parser.add_argument("--document_id", default="4086619433", help="Firestore Document ID")
    parser.add_argument("--config", help="Path to the JSON configuration file (required unless --batch_manifest is used)")
    parser.add_argument("--access_token", help="Optional OAuth2 access token for authentication")
    parser.add_argument("--batch_manifest", help="Path to a JSON manifest file for batch uploads")

    args = parser.parse_args()

    # If access_token is not passed as arg, check env var
    token = args.access_token or os.environ.get("GOOGLE_OAUTH_ACCESS_TOKEN")

    try:
        with open(args.config, 'r') as f:
            config_data = json.load(f)

        if isinstance(config_data, list):
            logger.info(f"Detected batch configuration list in {args.config}")
            for item in config_data:
                collection = item.get("collection_name")
                doc_id = item.get("document_id")
                data = item.get("data")

                if not collection or not doc_id or data is None:
                    logger.warning(f"Skipping invalid batch item: {item.keys()}")
                    continue

                # Upload directly using the inner data
                # We reuse the logic but avoiding reloading the file is cleaner,
                # but valid upload_config takes a PATH.
                # Refactoring upload_config to take data directly would be better,
                # but to minimize changes let's just use the logic inline or split it.
                # Actually, let's split upload_config into separate load and upload functions?
                # Or just write a quick helper here.

                # To keep it simple and safe, I will inline the upload logic here or call a helper.
                # Let's verify if I can just instantiate the client once.

                # REFACTOR: Let's extract the upload logic to a function that takes dict data.
                _upload_data(
                    project_id=args.project_id,
                    database=args.database,
                    collection_name=collection,
                    document_id=doc_id,
                    data=data,
                    access_token=token
                )
        else:
            # Single document mode
            upload_config(
                project_id=args.project_id,
                database=args.database,
                collection_name=args.collection_name,
                document_id=args.document_id,
                config_path=args.config,
                access_token=token
            )

    except Exception as e:
        logger.error(f"Execution failed: {e}")
        exit(1)



# -*- coding: utf-8 -*-
"""
Script to initialize the necessary Azure Cosmos DB containers for Mirai Cook.

Reads connection details via azure_clients module (which uses Key Vault).
Creates the database and containers if they don't already exist.
"""

import os
import sys
import logging
from azure.cosmos import CosmosClient, PartitionKey
from azure.cosmos.exceptions import CosmosResourceExistsError, CosmosHttpResponseError
from dotenv import load_dotenv

# --- Setup Project Root Path ---
# This allows the script to find the 'src' module when run from the 'scripts' directory
# Adjust the number of '..' if your script location relative to the root changes
project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
if project_root not in sys.path:
    sys.path.insert(0, project_root)

try:
    # Import the function to get the authenticated Cosmos client
    from src.azure_clients import get_cosmos_client, get_secrets_from_key_vault
except ImportError as e:
    print(f"Error: Could not import from src.azure_clients. Make sure the script is run correctly relative to the project root or PYTHONPATH is set. Details: {e}")
    sys.exit(1)

# --- Configuration ---
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# Database and Container Configuration
# Consider moving these to environment variables or a config file for more flexibility
DATABASE_NAME = os.getenv("COSMOS_DATABASE_NAME", "MiraiCookDB")
CONTAINERS_CONFIG = [
    {
        "name": os.getenv("RECIPE_CONTAINER_NAME", "Recipes"),
        "partition_key_path": "/id" # Partitioning by recipe ID for single user
    },
    {
        "name": os.getenv("PANTRY_CONTAINER_NAME", "Pantry"),
        "partition_key_path": "/id" # Partitioning by fixed ID for single user pantry
    },
    {
        "name": os.getenv("INGREDIENT_CONTAINER_NAME", "IngredientsMasterList"),
        "partition_key_path": "/id" # Partitioning by ingredient ID (sanitized name)
    }
    # Add other containers here if needed in the future
]

# --- Main Function ---
def setup_cosmos_db():
    """
    Connects to Cosmos DB and ensures the database and containers exist.
    """
    logger.info("--- Starting Cosmos DB Setup ---")

    # 1. Load Environment Variables (especially for Key Vault URI)
    if load_dotenv():
        logger.info("Loaded environment variables from .env file.")
    else:
        logger.info("No .env file found or it is empty. Relying on system environment variables.")

    # 2. Get Secrets (needed indirectly by get_cosmos_client if it uses keys)
    # Although get_cosmos_client might use Managed Identity directly in the future,
    # currently it likely relies on the key fetched via get_secrets...
    # If your get_cosmos_client truly only uses Managed Identity, this step might be skipped.
    logger.info("Retrieving secrets needed for Cosmos DB client initialization...")
    secrets = get_secrets_from_key_vault()
    if not secrets:
        logger.error("Failed to retrieve secrets from Key Vault. Aborting setup.")
        return False

    # 3. Get Cosmos Client
    logger.info("Initializing Cosmos DB client...")
    cosmos_client = get_cosmos_client(secrets)
    if not cosmos_client:
        logger.error("Failed to initialize Cosmos DB client. Aborting setup.")
        return False
    logger.info("Cosmos DB client initialized successfully.")

    # 4. Get or Create Database
    try:
        logger.info(f"Getting or creating database: '{DATABASE_NAME}'...")
        database_client = cosmos_client.create_database_if_not_exists(id=DATABASE_NAME)
        logger.info(f"Database '{database_client.id}' ensured.")
    except CosmosHttpResponseError as e:
        logger.error(f"Error interacting with database '{DATABASE_NAME}': {e.message}", exc_info=True)
        return False
    except Exception as e:
         logger.error(f"Unexpected error getting/creating database '{DATABASE_NAME}': {e}", exc_info=True)
         return False

    # 5. Create Containers
    all_containers_ok = True
    logger.info("Ensuring containers exist...")
    for container_config in CONTAINERS_CONFIG:
        container_name = container_config["name"]
        pk_path = container_config["partition_key_path"]
        try:
            logger.info(f"  Ensuring container '{container_name}' with partition key '{pk_path}'...")
            container_client = database_client.create_container_if_not_exists(
                id=container_name,
                partition_key=PartitionKey(path=pk_path)
                # You can add indexing policy, throughput settings etc. here if needed
                # offer_throughput=400 # Example for provisioned throughput
            )
            logger.info(f"  Container '{container_client.id}' ensured.")
        except CosmosResourceExistsError:
            logger.info(f"  Container '{container_name}' already exists.")
        except CosmosHttpResponseError as e:
            logger.error(f"  Error creating container '{container_name}': {e.message}", exc_info=True)
            all_containers_ok = False
        except Exception as e:
            logger.error(f"  Unexpected error creating container '{container_name}': {e}", exc_info=True)
            all_containers_ok = False

    if all_containers_ok:
        logger.info("--- Cosmos DB Setup Completed Successfully ---")
        return True
    else:
        logger.error("--- Cosmos DB Setup Finished with Errors ---")
        return False

# --- Script Execution ---
if __name__ == "__main__":
    setup_cosmos_db()

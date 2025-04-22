# MirAI Cook 🍳🤖

**Your personal and intelligent AI culinary assistant.**

Mirai Cook is a web application designed to be an advanced digital cookbook and kitchen helper, leveraging the power of Microsoft Azure AI services. It allows you to manage recipes, digitize them from images or import them from URLs, track your pantry, receive personalized suggestions, generate shopping lists, interact via voice, and much more.

## ✨ Key Features

* **Digital Cookbook:** Cloud database (Azure Cosmos DB) to save and organize your recipes.
* **Multi-modal Input:** Add recipes manually, digitize them from photos/scans (with Azure AI Document Intelligence + HITL), or import them from URLs (with `recipe-scrapers` + AI Fallback + HITL).
* **Pantry Management:** Keep track of the ingredients you have at home.
* **Master Ingredient List:** Centralized management of known ingredients with calorie caching and duplicate/similarity checks.
* **Automatic Categorization:** Classify recipes by course (Appetizer, First Course...) using Azure AI Language (with user confirmation HITL).
* **Dish Photo Analysis:** Associate photos with dishes and get automatic tags/descriptions with Azure AI Vision.
* **Calorie Estimation:** Approximate calorie calculation based on external food databases and local cache.
* **AI Suggestions (from Cookbook):** An AI agent (Semantic Kernel + Azure OpenAI) suggests recipes from your cookbook based on your pantry.
* **New Recipe Generation:** Ask Azure OpenAI to create brand new recipes tailored to your needs.
* **Shopping List:** Automatically generate a list of missing ingredients for chosen recipes (with download option).
* **Voice Interaction:** Dictate ingredients/instructions (Speech-to-Text) and listen to recipes (Text-to-Speech) using Azure AI Speech.
* **Advanced Search:** Find recipes in your cookbook using Azure AI Search with text search and filters/facets.
* **Intuitive UI:** Web interface developed with Streamlit, optimized for mobile.
* **Security:** Secure credential management via Azure Key Vault and Managed Identity/Service Principal.
* **Cloud-Native:** Designed for deployment on Azure (App Service / Container Apps).

## 🛠️ Tech Stack

* **Language:** Python 3.9+
* **UI Framework:** Streamlit
* **Database:** Azure Cosmos DB (NoSQL API)
* **Object Storage:** Azure Blob Storage
* **AI Services:**
    * Azure AI Services (Unified Resource for Vision, Language, Speech, Document Intelligence)
    * Azure OpenAI Service (GPT-3.5/GPT-4)
    * Azure AI Search
* **AI Orchestration:** Microsoft Semantic Kernel
* **Secret Management:** Azure Key Vault
* **Application Identity:** Azure Managed Identity / Service Principal
* **Deployment:** Docker, Azure App Service / Azure Container Apps

## 🚀 Local Setup and Installation

*(Section to be detailed)*

1.  **Clone the Repository:**
    ```bash
    git clone [https://github.com/LucaPaganin/mirai-cook.git](https://github.com/LucaPaganin/mirai-cook.git)
    cd mirai-cook
    ```
2.  **Create Virtual Environment:**
    ```bash
    python -m venv .venv
    source .venv/bin/activate  # Linux/macOS
    # or
    # .\.venv\Scripts\activate  # Windows
    ```
3.  **Install Dependencies:**
    ```bash
    pip install -r requirements.txt
    ```
4.  **Configure Environment Variables:**
    * Copy `.env.example` to `.env`.
    * Fill the `.env` file with your Azure credentials (Key Vault URI, SP/Managed Identity details, or direct keys for local testing if needed). **Never commit the `.env` file!**
5.  **Run the Streamlit App:**
    ```bash
    streamlit run app/mirai_cook.py # Or your main script name
    ```

## ☁️ Deployment

*(Section to be detailed)*

The application is designed to be containerized with Docker and deployed on Azure App Service or Azure Container Apps. Environment variables will need to be configured as secrets in the hosting platform, and ensure the managed identity (or service principal) has the correct permissions on Azure resources (Key Vault, Cosmos DB, etc.).

See the `Dockerfile` and potential deployment scripts or CI/CD pipelines.

## 📖 Usage

*(Section to be detailed with screenshots or GIFs)*

Briefly describe how to use the main features: adding recipes, managing the pantry, getting suggestions, etc.

## 🤝 Contributing

*(If applicable, add contribution guidelines)*

## 📄 License

This project is licensed under the MIT License. See the `LICENSE` file for details.
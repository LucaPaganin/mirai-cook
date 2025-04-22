# -*- coding: utf-8 -*-
"""
Main entry point for the Mirai Cook Streamlit application.
This script defines the Home/Welcome page and general app configurations.
The logic for individual pages is located in the 'pages/' folder.
"""

import streamlit as st
# Import other libraries needed for global configuration if necessary
# import os
# from dotenv import load_dotenv

# --- Streamlit Page Configuration ---
# NOTE: st.set_page_config() must be the first Streamlit command executed.
st.set_page_config(
    page_title="Mirai Cook AI",
    page_icon="🍳",  # You can choose an emoji or an icon URL
    layout="wide", # Use the full width of the page
    initial_sidebar_state="expanded" # Show the sidebar on startup
)

# --- Initial Configuration Loading (Optional) ---
# If you have global configurations or want to load .env immediately
# load_dotenv()
# print("Environment variables loaded.") # For debugging

# --- Home Page Content ---

st.title("Welcome to Mirai Cook! 🍳🤖")

st.markdown("""
Your personal culinary assistant powered by Artificial Intelligence.

**Explore the sections using the menu in the sidebar on the left:**

* **Recipe Book:** Browse, search, and view your saved recipes.
* **Add/Edit:** Manually enter new recipes or edit existing ones.
* **Import Recipe:** Add recipes by digitizing them from images/PDFs or importing from URLs.
* **Pantry Management:** Keep track of the ingredients you have available.
* **Ingredient Management:** View and manage the main list of ingredients known to the app.
* **AI Suggestions:** Ask the AI what to cook based on your recipe book and pantry, or have it generate completely new recipes.
* **Advanced Search:** Use the power of Azure AI Search to find recipes in your database.

*(This is the main page. The specific logic for each section is found in the corresponding files in the `pages/` folder)*
""")

# You can add a welcome image if you want
# try:
#     st.image("path/to/your/welcome_image.png", use_column_width=True)
# except FileNotFoundError:
#     st.warning("Welcome image not found.")

st.sidebar.success("Select a page above.")

# --- Additional Home Page Logic (if needed) ---
# For example, you could show a summary, the latest added recipes, etc.
# But keep this file lean; main logic goes in the other pages.

# --- Example of Session State Initialization (if you need a global state) ---
# if 'app_initialized' not in st.session_state:
#     st.session_state['app_initialized'] = True
#     st.session_state['user_id'] = "default_user" # For now, single user
#     # Initialize other global state variables if necessary
#     print("Session state initialized.")

# Remember: Most of the UI code and logic will go in the files
# inside the 'pages/' folder and in the modules inside 'src/'.

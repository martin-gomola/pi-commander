import streamlit as st
from views import dividends, tax_report

# Set page configuration
st.set_page_config(
    page_title="Slovak Tax Dividend Helper",
    layout="wide",
)

# Load custom CSS
def load_css():
    with open("assets/custom.css") as f:
        st.markdown(f"<style>{f.read()}</style>", unsafe_allow_html=True)

load_css()

# Custom sidebar navigation (this will be the only navigation)
st.sidebar.title("Navigation")
page = st.sidebar.radio("Go to", ["2024 Dividends", "2025 Tax Report"])

if page == "2024 Dividends":
    dividends.app()
elif page == "2025 Tax Report":
    tax_report.app()

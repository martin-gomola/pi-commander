# divvy_app/pages/dividends.py

import streamlit as st
import pandas as pd
from utils.data_processing import process_dividends

# List of countries with default data
COUNTRIES = [
    ("250", "Francúzsko", 0.25, "EUR"),  # France: 25% withholding tax, currency EUR
    ("840", "Spojené štáty americké", 0.15, "USD"),  # USA: 15% withholding tax, currency USD
]

def app():
    st.title("Slovak Tax Dividend Helper")
    st.header("Dividend Entry for 2024")
    
    # Conversion rate input
    conversion_rate_2024 = st.number_input("Enter USD to EUR conversion rate for 2024", value=1.0824, format="%.4f")
    st.write("Exchange rates can be found at [NBS](https://nbs.sk/statisticke-udaje/kurzovy-listok/mesacne-kumulativne-a-rocne-prehlady-kurzov/)")
    
    # Initialize session state dataframe
    if "df_2024" not in st.session_state:
        st.session_state["df_2024"] = pd.DataFrame()
    
    st.write("### Enter Dividend Details Manually")
    
    col1, col2 = st.columns([1, 1])
    selected_country = col1.selectbox("Select Country", [country[1] for country in COUNTRIES], index=0)
    country_data = next((country for country in COUNTRIES if country[1] == selected_country), None)
    default_tax = country_data[2] * 100 if country_data else 15
    default_currency = country_data[3] if country_data else "EUR"
    tax_input = col2.number_input(f"Tax % for {selected_country}", value=default_tax, min_value=0.0, format="%.2f")
    
    col3, col4, col5 = st.columns([2, 1, 1])
    dividends = col3.number_input("Dividends", min_value=0.0, format="%.2f")
    currency = col4.selectbox("Currency", ["EUR", "USD"], index=["EUR", "USD"].index(default_currency))
    source = col5.selectbox("Source", ["IBKR", "Revolut", "Schwab"])
    
    if st.button("Add Dividend", key="add_2024"):
        new_entry = {
            "Country": selected_country,
            "Dividends": dividends,
            "Currency": currency, 
            "Tax %": tax_input,
            "Source": source
        }
        st.session_state["df_2024"] = pd.concat([st.session_state["df_2024"], pd.DataFrame([new_entry])], ignore_index=True)
    
    if not st.session_state["df_2024"].empty:
        st.write("### Dividend Entries")
        st.dataframe(st.session_state["df_2024"])
        
        # Process the data
        summary = process_dividends(st.session_state["df_2024"], conversion_rate_2024, COUNTRIES)
        st.write("### Dividend Summary")
        st.dataframe(summary)
    else:
        st.write("No dividend entries found. Please add dividend data first.")

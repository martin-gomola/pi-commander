import streamlit as st
import pandas as pd

# List of countries and their default withholding tax rate and currency
countries = [
    ("250", "Francuzsko", 0.15, "EUR"),  # Country code, name, default tax rate, default currency
    ("840", "Spojene staty americke", 0.10, "USD"),
]

# Function to process dividends
def process_dividends(df, conversion_rate):
    # Convert dividends to EUR if necessary
    df["Dividends (EUR)"] = df.apply(lambda row: row["Dividends"] / conversion_rate if row["Currency"] == "USD" else row["Dividends"], axis=1)
    
    # Calculate after-tax dividends (subtracting the withholding tax)
    df["After Tax Dividends (EUR)"] = df.apply(lambda row: row["Dividends (EUR)"] * (1 - row["Tax %"]/100), axis=1)
    
    # Summarize by country
    summary = df.groupby("Country").agg({
        "Dividends (EUR)": "sum",
        "After Tax Dividends (EUR)": "sum"
    }).reset_index()

    # Only add "Dividends (USD)" for countries with USD currency
    for index, row in summary.iterrows():
        country = row['Country']
        # Find the country data from the original list
        country_data = next((item for item in countries if item[1] == country), None)
        if country_data and country_data[3] == "USD":
            # Sum only the USD dividends for countries with USD currency
            usd_dividends = df[(df["Country"] == country) & (df["Currency"] == "USD")]["Dividends"].sum()
            summary.at[index, "Dividends (USD)"] = usd_dividends
        else:
            summary.at[index, "Dividends (USD)"] = 0  # For countries that do not have USD, set it to 0
    
    return summary

# Streamlit UI
st.title("Slovak Tax Dividend Helper")

# Default exchange rate
conversion_rate = st.number_input("Enter USD to EUR conversion rate", value=1.0813, format="%.4f")

# Initialize session state for storing the DataFrame if not already initialized
if "df" not in st.session_state:
    st.session_state.df = pd.DataFrame()

# Manually input dividend details
st.write("### Enter Dividend Details Manually")
    
# Create columns for country and tax percentage
col1, col2 = st.columns([1, 1])

# Country select dropdown in the first column
selected_country = col1.selectbox("Select Country", [country[1] for country in countries])

# Find default tax percentage and currency for the selected country
country_data = next((country for country in countries if country[1] == selected_country), None)
tax_percentage = country_data[2] if country_data else 0.15
default_currency = country_data[3] if country_data else "EUR"

# Tax percentage input in the second column, with default value
tax_input = col2.number_input(f"Tax % for {selected_country}", value=tax_percentage * 100, min_value=0.0, format="%.2f")

# Create columns for Dividends, Currency input, and Source in one row
col3, col4, col5 = st.columns([2, 1, 1])

# Dividends input in the first column
dividends = col3.number_input("Dividends", min_value=0.0, format="%.2f")

# Currency input in the second column, preset based on selected country
currency = col4.selectbox("Currency", ["EUR", "USD"], index=["EUR", "USD"].index(default_currency))

# Source dropdown for where the dividend is coming from
source = col5.selectbox("Source", ["IBKR", "Revolut", "Schwab"])

# Add dividend entry to the session state dataframe
if st.button("Add Dividend"):
    new_entry = {
        "Country": selected_country,
        "Dividends": dividends,
        "Currency": currency, 
        "Tax %": tax_input,
        "Source": source
    }
    st.session_state.df = pd.concat([st.session_state.df, pd.DataFrame([new_entry])], ignore_index=True)

# Process and display summary if data is available
if not st.session_state.df.empty:
    # Display each entry in the dataframe (without Dividends EUR and After Tax Dividends)
    st.write("### Dividend Entries")
    st.dataframe(st.session_state.df.drop(columns=["Dividends (EUR)", "After Tax Dividends (EUR)"], errors='ignore'))

    # Process the data and calculate totals
    summary = process_dividends(st.session_state.df, conversion_rate)
    st.write("### Dividend Summary")
    st.dataframe(summary)  # Display the summary table in the app
else:
    st.write("No dividend entries found. Please add dividend data first.")

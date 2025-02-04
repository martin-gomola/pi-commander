import streamlit as st
import pandas as pd
import json
from utils.data_processing import process_dividends

# List of countries with default data
COUNTRIES = [
    ("250", "Francúzsko", 0.25, "EUR"),  # France: 25% withholding tax, currency EUR
    ("840", "Spojené štáty americké", 0.15, "USD"),  # USA: 15% withholding tax, currency USD
]

def df_to_text_table(df: pd.DataFrame) -> str:
    """
    Convert a DataFrame to a plain text table.
    Adjust the column widths based on the longest item in each column.
    """
    # Create header with column names
    col_widths = {
        col: max(df[col].astype(str).map(len).max(), len(col))
        for col in df.columns
    }
    header_row = "  ".join(f"{col:<{col_widths[col]}}" for col in df.columns)
    separator = "  ".join("─" * col_widths[col] for col in df.columns)
    rows = []
    for _, row in df.iterrows():
        formatted_row = "  ".join(f"{str(row[col]):<{col_widths[col]}}" for col in df.columns)
        rows.append(formatted_row)
    table = f"SUMMARY\n\n{header_row}\n{separator}\n" + "\n".join(rows)
    return table

def backup_data_to_json(df: pd.DataFrame) -> str:
    """
    Convert the DataFrame to a JSON string.
    """
    return df.to_json(orient="records", force_ascii=False, indent=2)

def load_data_from_json(json_data: str) -> pd.DataFrame:
    """
    Load dividend entries from a JSON string and convert to a DataFrame.
    """
    data = json.loads(json_data)
    return pd.DataFrame(data)

def app():
    st.title("Slovak Tax Dividend Helper")
    st.header("Dividend Entry for 2024")
    
    # Conversion rate input
    conversion_rate_2024 = st.number_input(
        "Enter USD to EUR conversion rate for 2024", value=1.0824, format="%.4f"
    )
    st.write("Exchange rates can be found at [NBS](https://nbs.sk/statisticke-udaje/kurzovy-listok/mesacne-kumulativne-a-rocne-prehlady-kurzov/)")
    
    # Initialize session state dataframe if not available
    if "df_2024" not in st.session_state:
        st.session_state["df_2024"] = pd.DataFrame()
    
    # --- Backup / Resume Section in a Collapsible Expander ---
    with st.expander("Backup / Resume Data"):
        col_backup, col_upload = st.columns(2)
        
        # Download Button: Export current data as JSON
        with col_backup:
            if not st.session_state["df_2024"].empty:
                json_backup = backup_data_to_json(st.session_state["df_2024"])
                st.download_button(
                    label="Download Backup (JSON)",
                    data=json_backup,
                    file_name="dividend_backup.json",
                    mime="application/json"
                )
            else:
                st.info("No data to backup.")
        
        # Upload JSON File: Import saved JSON data
        with col_upload:
            uploaded_file = st.file_uploader("Upload Backup (JSON)", type=["json"])
            if uploaded_file is not None:
                try:
                    file_content = uploaded_file.read().decode("utf-8")
                    df_loaded = load_data_from_json(file_content)
                    st.session_state["df_2024"] = df_loaded
                    st.success("Data loaded successfully!")
                except Exception as e:
                    st.error(f"Error loading data: {e}")
    
    st.write("### Enter Dividend Details Manually")
    
    # Dividend entry fields
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
        st.session_state["df_2024"] = pd.concat(
            [st.session_state["df_2024"], pd.DataFrame([new_entry])],
            ignore_index=True
        )
    
    # Display dividend entries (only show the manually-entered columns)
    if not st.session_state["df_2024"].empty:
        st.write("### Dividend Entries")
        entry_columns = ["Country", "Dividends", "Currency", "Tax %", "Source"]
        st.dataframe(st.session_state["df_2024"][entry_columns])
        
        # Process the data to produce a summary
        summary = process_dividends(st.session_state["df_2024"], conversion_rate_2024, COUNTRIES)
        
        # Let user choose the summary output format
        st.write("### Dividend Summary")
        output_format = st.radio("Select Summary Output Format", ["Text", "HTML"])
        
        if output_format == "HTML":
            # Convert the summary DataFrame to an HTML table.
            summary_html = summary.to_html(
                classes="table table-striped",
                border=0,
                index=False
            )
            st.markdown(summary_html, unsafe_allow_html=True)
        else:
            # Convert the DataFrame to a plain text table with a header
            summary_text = df_to_text_table(summary)
            st.code(summary_text, language="plaintext")
    else:
        st.write("No dividend entries found. Please add dividend data first.")

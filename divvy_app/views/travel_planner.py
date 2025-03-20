import streamlit as st
import pandas as pd
import json
from datetime import datetime, timedelta

# Default configuration
DEFAULT_CONFIG = {
    "start_date": datetime.today().strftime("%Y-%m-%d"),
    "duration_option": "Number of Days",
    "num_days": 10,
    "end_date": (datetime.today() + timedelta(days=9)).strftime("%Y-%m-%d"),
    "locations": ["Phuket", "Krabi (Ao Nang)", "Phi Phi", "Koh Lanta", "Koh Mook", "Koh Lipe", "Kuala Lumpur", "Budapest"],
    "accommodations": ["Hotel", "Bungalow", "Apartment"],
    "transports": ["Flight", "Train", "Bus", "Ferry", "Taxi", "Car"],
    "activities": ["Sightseeing", "Relaxing", "Hiking", "Swimming", "Shopping"]
}

def load_config():
    try:
        with open("config.json", "r") as f:
            config = json.load(f)
            config["start_date"] = datetime.strptime(config["start_date"], "%Y-%m-%d").date()
            if config.get("end_date"):
                try:
                    config["end_date"] = datetime.strptime(config["end_date"], "%Y-%m-%d").date()
                except ValueError:
                    pass
            return config
    except FileNotFoundError:
        return DEFAULT_CONFIG

def save_config(config):
    config_copy = config.copy()
    config_copy["start_date"] = config_copy["start_date"].strftime("%Y-%m-%d")
    if config_copy.get("end_date"):
        if hasattr(config_copy["end_date"], "strftime"):
            config_copy["end_date"] = config_copy["end_date"].strftime("%Y-%m-%d")
    with open("config.json", "w") as f:
        json.dump(config_copy, f, indent=4)

def generate_travel_plan(start_date, num_days=None, end_date=None):
    if num_days is None and end_date is None:
        return pd.DataFrame()

    if end_date:
        num_days = (end_date - start_date).days + 1

    dates = [start_date + timedelta(days=i) for i in range(num_days)]
    days = [(start_date + timedelta(days=i)).strftime("%a") for i in range(num_days)]

    df = pd.DataFrame({
        "Day": [i + 1 for i in range(num_days)],
        "Date": [date.strftime("%d/%m %a") for date in dates],
        "Location": [""] * num_days,
        "Accommodation": [""] * num_days,
        "Transport": [""] * num_days,
        "Activity": [""] * num_days,
        "Links to Book": [""] * num_days,
    })
    
    return df

def main():
    st.title("Travel Plan Generator")
    
    config = load_config()

    tab1, tab2 = st.tabs(["Settings", "Travel Plan"])

    with tab1:
        st.header("Settings")
        config["start_date"] = st.date_input("Start Date", config["start_date"])

        config["duration_option"] = st.radio("Choose how to define the trip duration:", ("Number of Days", "End Date"), index=("Number of Days", "End Date").index(config["duration_option"]))
        
        if config["duration_option"] == "Number of Days":
            config["num_days"] = st.number_input("Number of Days", min_value=1, value=config["num_days"])
        elif config["duration_option"] == "End Date":
            config["end_date"] = st.date_input("End Date", config["end_date"])

        config["locations"] = st.text_area("Locations (comma-separated)", ", ".join(config["locations"])).split(", ")
        config["accommodations"] = st.text_area("Accommodations (comma-separated)", ", ".join(config["accommodations"])).split(", ")
        config["transports"] = st.text_area("Transports (comma-separated)", ", ".join(config["transports"])).split(", ")
        config["activities"] = st.text_area("Activities (comma-separated)", ", ".join(config["activities"])).split(", ")
        
        if st.button("Save Configuration"):
            save_config(config)
            st.success("Configuration saved!")

    with tab2:
        st.header("Travel Plan")

        generate_button = st.button("Generate Plan")

        if generate_button:
            num_days = config["num_days"] if config["duration_option"] == "Number of Days" else None
            end_date = config["end_date"] if config["duration_option"] == "End Date" else None
            df = generate_travel_plan(config["start_date"], num_days, end_date)
            if not df.empty:
                st.session_state['edited_df'] = df.copy()

        if 'edited_df' in st.session_state:
            edited_df = st.data_editor(st.session_state['edited_df'],
                                        column_config={
                                            "Location": st.column_config.SelectboxColumn("Location", options=config["locations"], required=True),
                                            "Accommodation": st.column_config.SelectboxColumn("Accommodation", options=config["accommodations"]),
                                            "Transport": st.column_config.SelectboxColumn("Transport", options=config["transports"]),
                                            "Activity": st.column_config.SelectboxColumn("Activity", options=config["activities"])
                                        },
                                        num_rows="dynamic")

            if not edited_df.equals(st.session_state['edited_df']):
              st.session_state['edited_df'] = edited_df
              st.rerun() # Use st.rerun()

            csv = edited_df.to_csv(index=False).encode('utf-8')
            st.download_button(label="Download CSV", data=csv, file_name='travel_plan.csv', mime='text/csv')

        elif generate_button:
            st.warning("Please provide either the number of days or the end date.")

if __name__ == "__main__":
    main()
#!/usr/bin/env python
import pandas as pd
import numpy as np
import re

def transform_eurostat_data(file_name, na_rm=True):
  '''
  Preprocess Eurostat data.
  file_name: Str with location of an Eurostat dataset .tsv file
  returns:   Tuple with two pandas DataFrames. The first one has
             the values and the second one the metadata.
  
  
  The data is half comma separed, half tab separated.
  In order to obtain columns we import it with pandas
  under both configurations and then merge them.
  '''
  
  data_csv = pd.read_csv(file_name, sep=',', na_values=': ')
  data_tab = pd.read_csv(file_name, sep='\t', na_values=': ')
  
  '''
  The last comma separated column is mixed with the undetected columns
  either in the TSV or the CSV import.
  Its column label and values must be extracted manually.
  
  In data_tab, all comma columns are imported as one single
  column with long strings as values.
  '''
  # Identify mixed column
  mixed_column_label = list(data_tab)[0]
  data_tab.rename(columns={mixed_column_label: 'mixed'}, inplace=True)
  
  # Get last non-year-column values
  last_nonyear_col = []
  for string in data_tab.mixed:
    last_nonyear_col.append(string.split(',')[-1])
  data_tab.mixed = last_nonyear_col
  
  # Get last non-year-column label
  raw_col_label = mixed_column_label.split(',')[-1]
  col_label = re.match('\w+', raw_col_label)[0]
  data_tab = data_tab.rename(columns={'mixed': col_label})
  
  # Remove spaces from headers
  renamed_headers = {}
  for header in list(data_tab):
    renamed_headers[header] = header.strip()
  
  data_tab = data_tab.rename(columns=renamed_headers)
  
  # Remove mixed values column from data_csv
  mixed_column_label = list(data_csv)[-1]
  data_csv = data_csv.drop(columns=[mixed_column_label])
  
  # Merge columns
  data = pd.concat([data_csv, data_tab], axis=1)
  
  # Get a list of non year columns
  non_year_cols = list()
  for col_name in list(data):
    col_match = re.match('\d\d\d\d', col_name)
    if not isinstance(col_match, re.Match):
      non_year_cols.append(col_name)
      
  # Melt year columns in a single variable
  data = data.melt(id_vars=non_year_cols, var_name='year')
  data.year = pd.to_numeric(data.year)
  
  # Extract string metadata from values
  numbers_list = []
  letters_list = []
  
  for index, row in data.iterrows():
    value = row.value
    if isinstance(value, str):
      number = re.findall('[\d,.]+', value)
      # Some values don't have numbers, just
      # metadata tags, so we turn the numeric
      # DataFrame value to np.NaN
      if len(number)==0:
        number = np.NaN
      else:
        number = float(re.sub(',', '.', number[0]))
      letters = re.findall('[a-zA-Z]', value)
      letters = ''.join(letters)
    else:
      number = value
      letters = ''
    numbers_list.append(number)
    letters_list.append(letters)
  
  data.value = numbers_list
  data['metadata'] = letters_list
  
  # Remove NaN values
  if na_rm:
    data.dropna(subset=['value'], inplace=True)
  
  return(data)

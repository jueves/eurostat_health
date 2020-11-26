#!/usr/bin/env python
import pandas as pd
import numpy as np
import re

def import_eurostat_dataset(file_name, return_metadata=False):
  '''
  Preprocess Eurostat data.
  file_name: Str with location of an Eurostat dataset .tsv file
  returns:   Tuple with two pandas DataFrames. The first one has
             the values and the second one the metadata.
  '''
  
  '''
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
  
  # Get last non year column values
  last_nonyear_col = []
  for string in data_tab.mixed:
    last_nonyear_col.append(string.split(',')[-1])
  data_tab.mixed = last_nonyear_col
  
  # Get last non year column label
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
  
  # Split letters
  def extract_col_metadata(column):
    '''
    Takes a list of numbers with letters and returns a tuple which
    first element is a list of the numbers and the second a list with
    the strings for each number.
    Example: fun(['23 p', '21 pd']) -> ([23, 21], ['p', 'pd'])
    '''
    numbers_list = []
    letters_list = []
    for value in column:
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
    return((numbers_list, letters_list))
  
  # Create a metadata DataFrame for each year value
  metadata = pd.DataFrame()
  for col_name in list(data):
    # Check if the column name is a year
    re_output = re.fullmatch('\d\d\d\d', col_name)
    if isinstance(re_output, re.Match):
      # Procede with metadata extraction.
      data_col, metadata_col = extract_col_metadata(data[col_name])
      data[col_name] = data_col
      metadata[col_name] = metadata_col
    
      # Print value counts
      # Add value meaning from tags.json
      print(col_name+':')
      print(metadata[col_name].value_counts(), '\n')
  
  if return_metadata:
    output = (data, metadata)
  else:
    output = data
    
  return(output)

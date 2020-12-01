# This checks icd10 labels both in data and in code references in order to choose
# the most apropiate dictionary.

import transform_eurostat_data

# Extract labels
def extract_labels(file_name):
  data = transform_eurostat_data(file_name)
  return(list(set(data.icd10)))

def compare_labels(data_labels, code_labels_dic):
  # code_labels_dic: {'code_labels1':[], 'code_labels2':[]}
  in_out_df = pd.DataFrame(data_labels, columns=['data_labels'])
  in_out_df['data_labels'] = data_labels
  for key, value in code_labels_dic.items():
    in_out_df[key] = in_out_df.data_labels.apply(lambda x: (x in value))
    matches = sum(in_out_df[key])
    matches_per = round(matches*100/len(data_labels))
    print(key+':', str(matches), 'matches', '('+str(matches_per)+'%)')
  in_out_df = in_out_df.sort_values(list(in_out_df)[1:], ascending=False)
  return(in_out_df)

# Load code references
with open('data/icd10_2012.json') as f:
  icd10_2012 = json.load(f)

icd10_2012_edited = list(icd10_2012['names'].keys())
icd10_2012_orig = list(pd.read_csv('data/COD_2012_edited.csv')['ICD_10_original'])
icd10_2007 = list(pd.read_csv('data/COD_2007.csv')['Notation'])


my_label_dic =  {'2012_orig':icd10_2012_orig, '2012_edit': icd10_2012_edited, '2007': icd10_2007}

# deaths_stand
deaths_stand_labels = extract_labels('data/deaths_stand.gz')
compare_labels(deaths_stand_labels, my_label_dic)

# length_of_stay
length_labels = extract_labels('data/length_of_stay.gz')
compare_labels(length_labels, my_label_dic)

# deaths_crude
deaths_crude_labels = extract_labels('data/deaths_crude.gz')
compare_labels(deaths_crude_labels, my_label_dic)

# hosp_discharges
discharges_labels = extract_labels('data/hosp_discharges.gz')
compare_labels(discharges_labels, my_label_dic)

# hosp_discharges_and_length_of_stay
dicharges_and_length = extract_labels('data/hosp_discharges_and_length_of_stay.gz')
# "...has no atribute icd10"

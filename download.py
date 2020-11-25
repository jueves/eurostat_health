import requests
import json
import os.path

# Load datasets metadata
with open('data/datasets_metadata.json') as f:
  urls_dic = json.load(f)

for key, value in urls_dic.items():
  # Set name
  url = value['url']
  file_name = 'data/'+key+'.'+url.split('.')[-1]
  
  # Check if file exists
  if os.path.isfile(file_name):
    print(file_name, 'is already downloaded.')
  
  else:
    # Download dataset
    print('Downloading', key, 'dataset...')
    req = requests.get(url)
    
    # Save dataset
    with open(file_name, 'wb') as f:
      f.write(req.content)

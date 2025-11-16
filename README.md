<b>1) Description</b><br>
It is a lightweight PDF question-answer built with Streamlit + sentence-transformer + FAISS and deployed using Docker + Terraform with Nagios monitoring.<br>
<br>
<b>2) Build Stage</b><br>
Backend Logic: Custom Sentense safe chunking, embedding (sentence-transformer), FAISS indexing (cosine similarity) and retrieval, LLM prompt + response.<br>
StreamLit UI: Basic Frontend page to upload pdf and ask question.<br>
<br>
<b>3) Deployment Stage</b><br>
Containerisation using Docker.<br>
Infrastructure Management using Terraform.<br>
Basic HTTP monitoring using Nagios (inside a dockerised container with Terraform).
<br>
![Embedding](https://github.com/user-attachments/assets/89b93463-b275-454d-a00e-cd111a903cf2)
<br>
![Answer](https://github.com/user-attachments/assets/298dddce-9a71-476b-b3e7-17dbb182c425)
![Top_Retrieved_Chunks](https://github.com/user-attachments/assets/b6271f52-7937-4aa5-a596-40e180c85b4b)
![PDF References](https://github.com/user-attachments/assets/b7cb3728-ce4e-4398-99e6-fcf0720eeb3a)

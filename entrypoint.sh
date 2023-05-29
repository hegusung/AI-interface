#!/bin/sh

BRANCH=main
SHA=2f704b93c961bf202937b10aac9322b092afdce0

mkdir /app/repositories/alpaca_lora_4bit
git config --global http.postBuffer 1048576000
git clone https://github.com/johnsmith0031/alpaca_lora_4bit.git /app/repositories/alpaca_lora_4bit
cd /app/repositories/alpaca_lora_4bit || exit
git checkout ${BRANCH}
git reset --hard ${SHA}
echo "git+https://github.com/sterlind/GPTQ-for-LLaMa.git@lora_4bit" >> requirements.txt
pip install -r requirements.txt

cd /app || exit

exec "$@"

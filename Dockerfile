FROM nvidia/cuda:11.8.0-devel-ubuntu22.04 as builder

RUN apt-get update && \
    apt-get install --no-install-recommends -y git vim build-essential python3-dev python3-pip && \
    rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/oobabooga/GPTQ-for-LLaMa /build

WORKDIR /build

RUN pip install --upgrade pip setuptools && \
    pip install torch torchvision torchaudio && \
    pip install -r requirements.txt

ARG TORCH_CUDA_ARCH_LIST="8.6+PTX"
RUN python3 setup_cuda.py bdist_wheel -d .

FROM nvidia/cuda:11.8.0-runtime-ubuntu22.04

RUN apt-get update && \
    apt-get install --no-install-recommends -y libportaudio2 libasound-dev git python3 python3-dev python3-pip make g++ ninja-build cuda-compiler-11-8 && \
    rm -rf /var/lib/apt/lists/*

RUN pip install --upgrade pip setuptools && \
    pip install torch torchvision torchaudio

RUN mkdir /app

# WebUI
ARG BRANCH=main SHA=13e7ebfc7746fac5a76f9e889c34afcef940c9b7
RUN --mount=type=cache,target=/root/.cache/pip
RUN git config --global http.postBuffer 1048576000
RUN git clone https://github.com/oobabooga/text-generation-webui.git /app
WORKDIR /app
RUN git checkout ${BRANCH}
RUN git reset --hard ${SHA}
RUN cd /app/extensions/api && pip install -r requirements.txt
RUN cd /app/extensions/elevenlabs_tts && pip install -r requirements.txt
RUN cd /app/extensions/google_translate && pip install -r requirements.txt
RUN cd /app/extensions/silero_tts && pip install -r requirements.txt
RUN cd /app/extensions/whisper_stt && pip install -r requirements.txt
RUN cd /app && pip install -r requirements.txt

# Long Term Memory
#ARG BRANCH=master SHA=3e295748b12df7b178ffa2d61f1e9255ddc825fc
#RUN --mount=type=cache,target=/root/.cache/pip <<EOF
#mkdir -p /app/extensions/long_term_memory
#git config --global http.postBuffer 1048576000
#git clone https://github.com/wawawario2/long_term_memory.git /app/extensions/long_term_memory
#cd /app/extensions/long_term_memory
#git checkout ${BRANCH}
#git reset --hard ${SHA}
#pip install -r requirements.txt
#EOF

# Complex Memory
#ARG BRANCH=master SHA=1ac69b5b5e0d4a1f8c12785173604a914c6a81f6
#RUN --mount=type=cache,target=/root/.cache/pip <<EOF
#mkdir -p /app/extensions/complex_memory
#git config --global http.postBuffer 1048576000
#git clone https://github.com/theubie/complex_memory.git /app/extensions/complex_memory
#cd /app/extensions/complex_memory
#git checkout ${BRANCH}
#git reset --hard ${SHA}
#EOF

# Syntax Highlighting
#ARG BRANCH=master SHA=9d2ac886dcb38a0b31f8b6e2152ed69a2cd9b1b5
#RUN --mount=type=cache,target=/root/.cache/pip <<EOF
#mkdir -p /app/extensions/syntax_highlight
#git config --global http.postBuffer 1048576000
#git clone https://github.com/DavG25/text-generation-webui-code_syntax_highlight.git /app/extensions/syntax_highlight
#cd /app/extensions/syntax_highlight
#git checkout ${BRANCH}
#git reset --hard ${SHA}
#EOF

COPY --from=builder /build /app/repositories/GPTQ-for-LLaMa
RUN pip install /app/repositories/GPTQ-for-LLaMa/*.whl

COPY . /docker
RUN chmod +x /docker/entrypoint.sh

WORKDIR /app
ENV CLI_ARGS=""
ENTRYPOINT ["/docker/entrypoint.sh"]
CMD python3 server.py ${CLI_ARGS}

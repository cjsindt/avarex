FROM ubuntu:24.04

# Install dependencies
RUN apt-get update && apt-get install -y --fix-missing \
    curl \
    git \
    kmod \
    libglu1-mesa \
    openjdk-17-jdk \
    sudo \
    udev \
    unzip \
    vim \
    wget \
    xz-utils \
    zip \
    && rm -rf /var/lib/apt/lists/*

# Set JAVA_HOME
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PATH=$JAVA_HOME/bin:$PATH

# Install Flutter
RUN git clone https://github.com/flutter/flutter.git /opt/flutter -b stable
ENV PATH="/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:${PATH}"

RUN flutter doctor -v || true

# Install Android SDK
ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV PATH=$ANDROID_SDK_ROOT/platform-tols:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$PATH

RUN mkdir -p $ANDROID_SDK_ROOT/cmdline-tools && \
    cd $ANDROID_SDK_ROOT/cmdline-tools && \
    wget https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip -O cmdline-tools.zip && \
    unzip cmdline-tools.zip && \
    mv cmdline-tools latest && \
    rm cmdline-tools.zip

# Install Android SDK Components
RUN yes | sdkmanager --licenses && \
    sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0" "cmdline-tools;latest"

# Install flutterfire CLI
RUN dart pub global activate flutterfire_cli
ENV PATH="$PATH":"/root/.pub-cache/bin"

# Copy project files
WORKDIR /app
COPY . /app

# Run Flutter dependencies
RUN flutter pub get

# Expose Entrypoint
CMD ["bash"]


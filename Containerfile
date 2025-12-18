FROM ubuntu:24.04

# Install dependencies
RUN apt-get update && apt-get install -y --fix-missing --fix-broken \
    build-essential \
    clang-16 \
    clang++-16 \
    cmake \
    curl \
    git \
    kmod \
    libglu1-mesa \
    libgstreamer1.0-dev \
    libgstreamer-plugins-base1.0-dev \
    libgstreamer-plugins-bad1.0-dev \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-ugly \
    gstreamer1.0-libav \
    gstreamer1.0-tools \
    gstreamer1.0-x \
    gstreamer1.0-alsa \
    gstreamer1.0-gl \
    gstreamer1.0-gtk3 \
    gstreamer1.0-qt5 \
    gstreamer1.0-pulseaudio \
    libgtk-3-dev \
    openjdk-17-jdk \
    pkg-config \
    ninja-build \
    sudo \
    udev \
    unzip \
    vim \
    wget \
    xz-utils \
    zip \
    && rm -rf /var/lib/apt/lists/*

# Symlink Clang
RUN ln -s /usr/bin/clang++-16 /usr/bin/clang++

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


# Use the official Dart image.
FROM google/dart:latest

# Set the working directory.
WORKDIR /app

# Copy the pubspec files and get dependencies.
COPY pubspec.* ./
RUN dart pub get

# Copy the rest of the application code.
COPY . .

# Compile the server.
RUN dart compile exe bin/server.dart -o bin/server

# Expose the port the app runs on.
EXPOSE 8080

# Run the server.
CMD ["bin/server"]

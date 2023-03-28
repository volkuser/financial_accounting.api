FROM google/dart:latest

WORKDIR /app

COPY pubspec.* ./
RUN pub get
COPY . .
RUN dart compile exe bin/main.dart -o bin/app

CMD ["bin/app"]

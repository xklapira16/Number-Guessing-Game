#!/bin/bash

# Set PSQL variable to interact with PostgreSQL
db_name="number_guess"
PSQL="psql --username=freecodecamp --dbname=$db_name -t --no-align -c"

# Ensure the database and table exist
$PSQL "CREATE TABLE IF NOT EXISTS users (username VARCHAR(22) PRIMARY KEY, games_played INT DEFAULT 0, best_game INT DEFAULT NULL);"

# Generate a random number between 1 and 1000
SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))

# Prompt for username
echo "Enter your username:"
read USERNAME

# Check if user exists
USER_DATA=$($PSQL "SELECT games_played, best_game FROM users WHERE username='$USERNAME'")

if [[ -z "$USER_DATA" ]]; then
  echo "Welcome, $USERNAME! It looks like this is your first time here."
  $PSQL "INSERT INTO users (username, games_played) VALUES ('$USERNAME', 0);"
else
  IFS='|' read -r GAMES_PLAYED BEST_GAME <<< "$USER_DATA"
  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

# Start the guessing game
echo "Guess the secret number between 1 and 1000:"
ATTEMPTS=0
while true; do
  read GUESS
  ((ATTEMPTS++))
  
  if ! [[ "$GUESS" =~ ^[0-9]+$ ]]; then
    echo "That is not an integer, guess again:"
  elif (( GUESS < SECRET_NUMBER )); then
    echo "It's higher than that, guess again:"
  elif (( GUESS > SECRET_NUMBER )); then
    echo "It's lower than that, guess again:"
  else
    echo "You guessed it in $ATTEMPTS tries. The secret number was $SECRET_NUMBER. Nice job!"
    break
  fi
done

# Update user stats in database
$PSQL "UPDATE users SET games_played = games_played + 1 WHERE username='$USERNAME';"

if [[ -z "$BEST_GAME" || ATTEMPTS -lt BEST_GAME ]]; then
  $PSQL "UPDATE users SET best_game = $ATTEMPTS WHERE username='$USERNAME';"
fi

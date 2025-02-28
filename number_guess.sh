#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

# Prompt for username
echo -n "Enter your username: "
read USERNAME

# Check if username exists in the database
USER_INFO=$($PSQL "SELECT user_id, COUNT(*), MIN(number_guesses) FROM users LEFT JOIN games ON users.user_id = games.user_id WHERE username='$USERNAME' GROUP BY users.user_id")

if [[ -z $USER_INFO ]]; then
  # New user
  echo "Welcome, $USERNAME! It looks like this is your first time here."
  $PSQL "INSERT INTO users (username) VALUES ('$USERNAME')"
  USER_ID=$($PSQL "SELECT user_id FROM users WHERE username='$USERNAME'")
else
  # Existing user
  IFS="|" read USER_ID GAMES_PLAYED BEST_GAME <<< "$USER_INFO"
  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

# Generate secret number
SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))
echo -n "Guess the secret number between 1 and 1000: "

# Initialize guess count
NUMBER_OF_GUESSES=0

while true; do
  read GUESS
  ((NUMBER_OF_GUESSES++))

  # Check if input is an integer
  if ! [[ $GUESS =~ ^[0-9]+$ ]]; then
    echo -n "That is not an integer, guess again: "
    continue
  fi

  # Convert guess to integer
  GUESS=$((GUESS))

  # Check if guess is correct
  if (( GUESS == SECRET_NUMBER )); then
    echo "You guessed it in $NUMBER_OF_GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"
    
    # Insert game record
    $PSQL "INSERT INTO games (user_id, number_guesses) VALUES ($USER_ID, $NUMBER_OF_GUESSES)"
    break
  elif (( GUESS > SECRET_NUMBER )); then
    echo -n "It's lower than that, guess again: "
  else
    echo -n "It's higher than that, guess again: "
  fi
done

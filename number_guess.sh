#!/bin/bash

# PostgreSQL command shortcut
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

# Prompt for username
echo "Enter your username:"
read USERNAME

# Check if user exists
USER_ID=$($PSQL "SELECT user_id FROM users WHERE username='$USERNAME'")

if [[ -z $USER_ID ]]
then
  # First-time user
  echo "Welcome, $USERNAME! It looks like this is your first time here."
  INSERT_USER=$($PSQL "INSERT INTO users(username) VALUES('$USERNAME')")
  USER_ID=$($PSQL "SELECT user_id FROM users WHERE username='$USERNAME'")
  GAMES_PLAYED=0
  BEST_GAME=0
else
  # Returning user
  USER_DATA=$($PSQL "SELECT games_played,best_game FROM users WHERE user_id=$USER_ID")
  
  # Split the data into two variables
  IFS='|' read GAMES_PLAYED BEST_GAME <<< "$USER_DATA"

  # Trim whitespace
  GAMES_PLAYED=$(echo $GAMES_PLAYED | xargs)
  BEST_GAME=$(echo $BEST_GAME | xargs)

  # Ensure best_game is not empty
  if [[ -z $BEST_GAME ]]; then BEST_GAME=0; fi

  # Exact required message
  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

# Generate secret number
SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))

echo "Guess the secret number between 1 and 1000:"
NUMBER_OF_GUESSES=0

while read GUESS
do
  # Validate integer input
  if [[ ! $GUESS =~ ^[0-9]+$ ]]
  then
    echo "That is not an integer, guess again:"
    continue
  fi

  (( NUMBER_OF_GUESSES++ ))

  if (( GUESS == SECRET_NUMBER ))
  then
    # Final success message (single line, exact format)
    echo "You guessed it in $NUMBER_OF_GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"

    # Update stats
    if [[ -z $BEST_GAME || $NUMBER_OF_GUESSES -lt $BEST_GAME || $BEST_GAME -eq 0 ]]
    then
      BEST_GAME=$NUMBER_OF_GUESSES
    fi
    (( GAMES_PLAYED++ ))

    UPDATE_USER=$($PSQL "UPDATE users SET games_played=$GAMES_PLAYED, best_game=$BEST_GAME WHERE user_id=$USER_ID")
    break
  elif (( GUESS > SECRET_NUMBER ))
  then
    echo "It's lower than that, guess again:"
  else
    echo "It's higher than that, guess again:"
  fi
done

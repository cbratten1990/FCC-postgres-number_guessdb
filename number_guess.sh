#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess --tuples-only -c"

SECRET_NUMBER=$((1 + RANDOM % 1000))
NUM_GUESSES=0

# ask user for their name
echo "Enter your username:"
read USERNAME
USER_INFO=$($PSQL "SELECT * FROM users WHERE username ILIKE '$USERNAME'") 
# check if user exists
if [[ -z $USER_INFO ]]
then
  # if user doesn't exist
  INSERT_USER_RESULT=$($PSQL "INSERT INTO users(username) VALUES('$USERNAME')")
  # insert new user
  if [[ $INSERT_USER_RESULT == 'INSERT 0 1' ]]
  then
    # get new user_id
    # echo -e "\nYou've made it to this part!"
    # start game loop
    echo "Welcome, $USERNAME! It looks like this is your first time here."
    echo "Guess the secret number between 1 and 1000:"
    read GUESS
    while true
    do
      if ! [[ "$GUESS" =~ ^[0-9]+$ ]]
      then
        echo "That is not an integer, guess again:"
        read GUESS
        continue
      fi
      (( NUM_GUESSES++ ))
      if [[ "$GUESS" -eq "$SECRET_NUMBER" ]]
      then
        # insert the rest of information into history database
        INSERT_HISTORY_RESULT=$($PSQL "INSERT INTO history(username, guess_count, secret_number, game_result, user_id) VALUES('$USERNAME', $NUM_GUESSES, $SECRET_NUMBER, 'Won', (SELECT user_id FROM users WHERE username = '$USERNAME'))")
        echo "You guessed it in $NUM_GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"
        #if [[ $INSERT_HISTORY_RESULT == 'INSERT 0 1' ]]
        #then
          #echo "You've got this!!!"
        #fi
        break
      elif [[ "$GUESS" -lt "$SECRET_NUMBER" ]]
      then
        echo "It's higher than that, guess again:"
        read GUESS
        continue
      else
        echo "It's lower than that, guess again:"
        read GUESS
        continue
      fi
    done
  fi
else
  # user was found
  # format a message with the user information
  echo "$USER_INFO" | while read USER_ID BAR USERNAME BAR
  do
    # get user info into separate variables
    BEST_GAME_RAW=$($PSQL "SELECT MIN(guess_count) FROM history WHERE user_id = $USER_ID")
    GAME_COUNT_RAW=$($PSQL "SELECT COUNT(*) FROM history WHERE user_id = $USER_ID")
    BEST_GAME=$(echo "$BEST_GAME_RAW" | sed -E 's/^[[:space:]]*|[[:space:]]*$//')
    GAME_COUNT=$(echo "$GAME_COUNT_RAW" | sed -E 's/^[[:space:]]*|[[:space:]]*$//')
    # format message to returning user
    echo "Welcome back, $USERNAME! You have played $GAME_COUNT games, and your best game took $BEST_GAME guesses." 
  done
  echo "Guess the secret number between 1 and 1000:"
  read GUESS
  # start game loop for returning users
  while true
  do
    if ! [[ "$GUESS" =~ ^[0-9]+$ ]]
    then
      echo "That is not an integer, guess again:"
      read GUESS
      continue
    fi
    (( NUM_GUESSES++ ))

    if [[ "$GUESS" -eq "$SECRET_NUMBER" ]]
    then
      # insert results in history table
      INSERT_HISTORY_RESULT=$($PSQL "INSERT INTO history(username, guess_count, secret_number, game_result, user_id) VALUES('$USERNAME', $NUM_GUESSES, $SECRET_NUMBER, 'Won', $USER_ID")
      echo "You guessed it in $NUM_GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"
      break
    elif [[ "$GUESS" -lt "$SECRET_NUMBER" ]]
    then
      echo "It's higher than that, guess again:"
      read GUESS
      continue
    else
      echo "It's lower than that, guess again:"
      read GUESS
      continue
    fi
  done
fi

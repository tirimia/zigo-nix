package main

import (
	"database/sql"
	"log"

	_ "github.com/mattn/go-sqlite3"
)

func main() {
	db, err := sql.Open("sqlite3", "file:db.sqlite")
	if err != nil {
		log.Fatal(err)
	}
	defer db.Close()
}

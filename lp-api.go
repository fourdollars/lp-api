package main

import (
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"net/url"
	"time"
)

func request_token() (string, string) {
	resp, err := http.PostForm("https://launchpad.net/+request-token",
		url.Values{
			"oauth_consumer_key":     {"System-wide: golang (lp-api)"},
			"oauth_signature_method": {"PLAINTEXT"},
			"oauth_signature":        {"&"},
		},
	)
	if err != nil {
		panic(err)
	}
	defer resp.Body.Close()
	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		panic(err)
	}
	mesg := string(body)
	log.Print(mesg)
	m, err := url.ParseQuery(mesg)
	if err != nil {
		panic(err)
	}
	return m["oauth_token"][0], m["oauth_token_secret"][0]
}

func access_token(oauth_token string, oauth_token_secret string) (string, string) {
again:
	time.Sleep(5 * time.Second)
	resp, err := http.PostForm("https://launchpad.net/+access-token",
		url.Values{
			"oauth_token":            {oauth_token},
			"oauth_consumer_key":     {"System-wide: golang (lp-api)"},
			"oauth_signature_method": {"PLAINTEXT"},
			"oauth_signature":        {"&" + oauth_token_secret},
		},
	)
	if err != nil {
		panic(err)
	}
	defer resp.Body.Close()
	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		panic(err)
	}
	mesg := string(body)
	if mesg == "Request token has not yet been reviewed. Try again later." {
		goto again
	} else if mesg == "End-user refused to authorize request token." {
		panic(mesg)
	}
	log.Print(mesg)
	m, err := url.ParseQuery(mesg)
	if err != nil {
		panic(err)
	}
	return m["oauth_token"][0], m["oauth_token_secret"][0]
}

func main() {
	oauth_token, oauth_token_secret := request_token()
	fmt.Printf("Please open https://launchpad.net/+authorize-token?oauth_token=%s&allow_permission=DESKTOP_INTEGRATION to authorize the token.\n", oauth_token)
	access_token(oauth_token, oauth_token_secret)
}

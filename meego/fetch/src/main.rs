//! radelt-fetch: one HTTPS request for the MeeGo edition of Radelt.
//!
//!     radelt-fetch --method POST --url https://... --header "Name: value" ...
//!
//! The request body is read from stdin (a recorded track is far too large
//! for an argument list, and it would stand in the process list for anyone
//! to read). The answer body goes to stdout unchanged; the HTTP status goes
//! to stderr as the last line, "status: 200". That is the contract
//! ProcessHttp in src/http.cpp expects.
//!
//! Exit code 0 means an answer arrived, whatever its status; 1 means the
//! request never got that far, and stderr then carries the reason instead.
//!
//! Built statically against musl, so Harmattan's glibc 2.10 and its OpenSSL
//! play no part.
use std::env;
use std::io::{Read, Write};
use std::process;
use std::time::Duration;

fn main() {
    let mut method = String::from("GET");
    let mut url = String::new();
    let mut headers: Vec<(String, String)> = Vec::new();

    let mut args = env::args().skip(1);
    while let Some(argument) = args.next() {
        match argument.as_str() {
            "--method" => method = args.next().unwrap_or_default(),
            "--url" => url = args.next().unwrap_or_default(),
            "--header" => {
                if let Some(line) = args.next() {
                    if let Some((name, value)) = line.split_once(':') {
                        headers.push((name.trim().to_string(), value.trim().to_string()));
                    }
                }
            }
            other => {
                eprintln!("unknown argument {}", other);
                process::exit(2);
            }
        }
    }

    if url.is_empty() {
        eprintln!("usage: radelt-fetch --method VERB --url URL [--header 'Name: value']...");
        process::exit(2);
    }

    let mut body = Vec::new();
    // Reading stdin to the end also covers the empty case: the caller
    // closes the channel right away for a GET.
    let _ = std::io::stdin().read_to_end(&mut body);

    match send(&method, &url, &headers, body) {
        Ok((status, answer)) => {
            let _ = std::io::stdout().write_all(&answer);
            let _ = std::io::stdout().flush();
            eprintln!("status: {}", status);
        }
        Err(reason) => {
            eprintln!("{}", reason);
            process::exit(1);
        }
    }
}

fn send(
    method: &str,
    url: &str,
    headers: &[(String, String)],
    body: Vec<u8>,
) -> Result<(u16, Vec<u8>), String> {
    let client = reqwest::blocking::Client::builder()
        // A phone on a bicycle loses the network often enough that a
        // request must give up by itself rather than hold the upload queue.
        .timeout(Duration::from_secs(45))
        .user_agent("harbour-radelt/0.1 (MeeGo Harmattan)")
        .build()
        .map_err(|e| e.to_string())?;

    let verb = reqwest::Method::from_bytes(method.as_bytes())
        .map_err(|_| format!("unknown method {}", method))?;
    let mut request = client.request(verb, url);
    for (name, value) in headers {
        request = request.header(name.as_str(), value.as_str());
    }
    if !body.is_empty() {
        request = request.body(body);
    }

    let response = request.send().map_err(|e| e.to_string())?;
    let status = response.status().as_u16();
    let answer = response.bytes().map_err(|e| e.to_string())?.to_vec();
    Ok((status, answer))
}

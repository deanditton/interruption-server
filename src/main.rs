use std::collections::HashMap;
use std::convert::Infallible;
use std::sync::Arc;
use tokio::sync::{mpsc, RwLock};
use warp::{ws::Message, Filter, Rejection};

mod handler;
mod ws;

type Result<T> = std::result::Result<T, Rejection>;
type Clients = Arc<RwLock<HashMap<String, Client>>>;
type UserId = String;
type ReceiverId = UserId;

#[derive(Debug, Clone)]
pub struct Client {
    pub user_id: UserId,
    // pub topics: Vec<String>,
    pub sender: Option<mpsc::UnboundedSender<std::result::Result<Message, warp::Error>>>,
}

#[tokio::main]
async fn main() {
    pretty_env_logger::init();

    let log = warp::log("example::api");

    let clients: Clients = Arc::new(RwLock::new(HashMap::new()));

    let health_route = warp::path!("health").and_then(handler::health_handler);

    let cors = warp::cors()
        .allow_any_origin()
        .allow_methods(vec!["GET", "POST", "PATCH", "OPTIONS", "DELETE"])
        .allow_headers(vec!["Content-Type", "User-Agent", "Sec-Fetch-Mode", "Referer", "Accept", "Origin", "Access-Control-Request-Method", "Access-Control-Request-Headers"]);
    // .allow_methods(vec!["POST", "GET"]);

    let register = warp::path("register");
    let register_routes = register
        .and(warp::post())
        .and(warp::body::json())
        .and(with_clients(clients.clone()))
        .and_then(handler::register_handler)
        .or(register
            .and(warp::delete())
            .and(warp::path::param())
            .and(with_clients(clients.clone()))
            .and_then(handler::unregister_handler));

    let publish = warp::path!("publish")
        .and(warp::body::json())
        .and(with_clients(clients.clone()))
        .and_then(handler::publish_handler);

    let ws_route = warp::path("ws")
        .and(warp::ws())
        .and(warp::path::param())
        .and(with_clients(clients.clone()))
        .and_then(handler::ws_handler);

    let routes = health_route
        .or(register_routes)
        .or(ws_route)
        .or(publish)
        .with(cors)
        .with(log);

    warp::serve(routes).run(([0, 0, 0, 0], 9231)).await;
        // .tls()
        // .cert_path("cert.pem")
        // .key_path("key.rsa")

}

fn with_clients(clients: Clients) -> impl Filter<Extract=(Clients, ), Error=Infallible> + Clone {
    warp::any().map(move || clients.clone())
}

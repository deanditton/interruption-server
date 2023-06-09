use crate::{ws, Client, Clients, Result, UserId, ReceiverId};
use serde::{Deserialize, Serialize};
use uuid::Uuid;
use warp::{http::StatusCode, reply::json, ws::Message, Reply};


#[derive(Deserialize, Debug)]
pub struct RegisterRequest {
    user_id: UserId,
}

#[derive(Serialize, Debug)]
pub struct RegisterResponse {
    url: UserId,
}

#[derive(Deserialize, Debug)]
pub struct Event {
    receiver: Option<ReceiverId>,
    sender_id: UserId,
    message: String,
}

pub async fn publish_handler(body: Event, clients: Clients) -> Result<impl Reply> {
    clients
        .read()
        .await
        .iter()
        .filter(|(_, client)| match &body.receiver {
            Some(v) => &client.user_id == v,
            None => true,
        })
        // .filter(|(_, client)| client.topics.contains(&body.topic))
        .for_each(|(_, client)| {
            if let Some(sender) = &client.sender {
                let _ = sender.send(Ok(Message::text(body.message.clone())));
            }
        });
    Ok(StatusCode::OK)
}

pub async fn register_handler(body: RegisterRequest, clients: Clients) -> Result<impl Reply> {
    let user_id = body.user_id;
    let uuid = Uuid::new_v4().as_simple().to_string();

    register_client(uuid.clone(), user_id, clients).await;
    Ok(json(&RegisterResponse {
        url: format!("ws://0.0.0.0:9231/ws/{}", uuid),
    }))
}

async fn register_client(id: String, user_id: UserId, clients: Clients) {
    clients.write().await.insert(
        id,
        Client {
            user_id,
            // topics: vec![String::from("cats")],
            sender: None,
        },
    );
}

pub async fn unregister_handler(id: String, clients: Clients) -> Result<impl Reply> {
    clients.write().await.remove(&id);
    Ok(StatusCode::OK)
}

pub async fn ws_handler(ws: warp::ws::Ws, id: String, clients: Clients) -> Result<impl Reply> {
    let client = clients.read().await.get(&id).cloned();
    match client {
        Some(c) => Ok(ws.on_upgrade(move |socket| ws::client_connection(socket, id, clients, c))),
        None => Err(warp::reject::not_found()),
    }
}

pub async fn health_handler() -> Result<impl Reply> {
    Ok(StatusCode::OK)
}
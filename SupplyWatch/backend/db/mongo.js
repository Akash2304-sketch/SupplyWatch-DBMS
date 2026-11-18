import { MongoClient } from "mongodb";
import dotenv from "dotenv";
dotenv.config();

let client;
let database;

export async function getMongoDb() {
  if (!process.env.MONGODB_URI) return null;
  if (!client) {
    client = new MongoClient(process.env.MONGODB_URI);
    await client.connect();
    database = client.db(process.env.MONGODB_DATABASE || "supplywatch_nosql");
  }
  return database;
}

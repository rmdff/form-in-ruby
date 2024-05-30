require "sinatra"
require "sinatra/cross_origin"
require "sqlite3"
require "json"

set :port, 8080
configure { enable :cross_origin }
before { response.headers["Access-Control-Allow-Origin"] = "*" }

options "*" do
  response.headers["Access-Control-Allow-Methods"] = "GET, POST, PUT, DELETE, OPTIONS"
  response.headers["Access-Control-Allow-Headers"] = "Content-Type"
  200
end

not_found { "༼ つ ◕_◕ ༽つ" }

db = SQLite3::Database.new "formulario.db"
db.results_as_hash = true
db.execute <<-SQL
  CREATE TABLE IF NOT EXISTS formulario(
    id INTEGER PRIMARY KEY,
    nome TEXT,
    email VARCHAR,
    tel VARCHAR,
    rua TEXT,
    numero INT,
    cidade TEXT,
    cep VARCHAR,
    bairro TEXT
  );
SQL

post "/form" do
  content_type :json
  nome = params["txt-nome"]
  email = params["txt-email"]
  tel = params["txt-tel"]
  rua = params["txt-rua"]
  numero = params["txt-numero"]
  cidade = params["txt-cidade"]
  cep = params["txt-cep"]
  bairro = params["txt-bairro"]

  if nome && email && tel && rua && numero && cidade && cep && bairro
    result = db.get_first_value("SELECT COUNT(*) FROM formulario WHERE email = ? OR tel = ?", [email, tel])
    if result.to_i > 0
      {code: 0, message: "Email ou telefone já cadastrados"}.to_json
    else
      db.execute "INSERT INTO formulario (nome, email, tel, rua, numero, cidade, cep, bairro) VALUES (?, ?, ?, ?, ?, ?, ?, ?)", [nome, email, tel, rua, numero, cidade, cep, bairro]
      {code: 1, message: "Cadastro realizado com sucesso"}.to_json
    end
  else
    {code: 2, message: "Todos os campos são obrigatórios"}.to_json
  end
end

get "/data" do
  content_type :json
  data = db.execute("SELECT * FROM formulario")
  formatted_data = data.map do |row|
    {
      id: row["id"],
      nome: row["nome"],
      email: row["email"],
      tel: row["tel"],
      rua: row["rua"],
      numero: row["numero"],
      cidade: row["cidade"],
      cep: row["cep"],
      bairro: row["bairro"]
    }
  end
  formatted_data.to_json
end

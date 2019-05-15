defmodule OriginSimulatorTest do
  use ExUnit.Case
  use Plug.Test

  doctest OriginSimulator

  setup do
    OriginSimulator.Simulation.restart()
    Process.sleep(10)
  end

  describe "GET /status" do
    test "will return 'OK'" do
      conn = conn(:get, "/status") |> OriginSimulator.call([])

      assert conn.state == :sent
      assert conn.status == 200
      assert get_resp_header(conn, "content-type") == ["text/plain; charset=utf-8"]
      assert conn.resp_body == "ok!"
    end
  end

  describe "GET /current_recipe" do
    test "will return an error message if payload has not been set" do
      conn = conn(:get, "/current_recipe") |> OriginSimulator.call([])

      assert conn.state == :sent
      assert conn.status == 200
      assert get_resp_header(conn, "content-type") == ["application/json; charset=utf-8"]
      assert conn.resp_body ==  "\"Not set, please POST a recipe to /add_recipe\""
    end

    test "will return the payload if set" do
      payload = %{
        "origin" => "https://www.bbc.co.uk/news",
        "stages" => [%{ "at" => 0, "status" => 200, "latency" => 100}],
        "random" => nil,
        "body"   => nil
      }

      conn(:post, "/add_recipe", Poison.encode!(payload)) |> OriginSimulator.call([])

      conn = conn(:get, "/current_recipe")
      conn = OriginSimulator.call(conn, [])

      assert conn.state == :sent
      assert conn.status == 200
      assert get_resp_header(conn, "content-type") == ["application/json; charset=utf-8"]
      assert Poison.decode!(conn.resp_body) == payload
    end
  end

  describe "GET page with origin" do
    test "will return the origin page" do
      payload = %{
        "origin" => "https://www.bbc.co.uk/news",
        "stages" => [%{ "at" => 0, "status" => 200, "latency" => 0}]
      }

      conn(:post, "/add_recipe", Poison.encode!(payload)) |> OriginSimulator.call([])

      Process.sleep 20

      conn = conn(:get, "/")
      conn = OriginSimulator.call(conn, [])

      assert conn.state == :sent
      assert conn.status == 200
      assert get_resp_header(conn, "content-type") == ["text/html; charset=utf-8"]
      assert conn.resp_body == "some content from origin"
    end
  end

  describe "GET page with content" do
    test "will return the origin page" do
      payload = %{
        "body" =>   "{\"hello\":\"world\"}",
        "stages" => [%{ "at" => 0, "status" => 200, "latency" => 0}]
      }

      conn(:post, "/add_recipe", Poison.encode!(payload)) |> OriginSimulator.call([])

      Process.sleep 20

      conn = conn(:get, "/")
      conn = OriginSimulator.call(conn, [])

      assert conn.state == :sent
      assert conn.status == 200
      assert get_resp_header(conn, "content-type") == ["application/json; charset=utf-8"]
      assert conn.resp_body == "{\"hello\":\"world\"}"
    end
  end

  describe "GET page with random latency within range" do
    test "will return the origin page" do
      payload = %{
        "body" =>   "{\"hello\":\"world\"}",
        "stages" => [%{ "at" => 0, "status" => 200, "latency" => "10ms..50ms"}]
      }

      conn(:post, "/add_recipe", Poison.encode!(payload)) |> OriginSimulator.call([])

      Process.sleep 20

      conn = conn(:get, "/")
      conn = OriginSimulator.call(conn, [])

      assert conn.state == :sent
      assert conn.status == 200
      assert get_resp_header(conn, "content-type") == ["application/json; charset=utf-8"]
      assert conn.resp_body == "{\"hello\":\"world\"}"
    end
  end

  describe "POST page with origin" do
    test "will return the simulated page" do
      payload = %{
        "origin" => "https://www.bbc.co.uk/news",
        "stages" => [%{ "at" => 0, "status" => 200, "latency" => 0}]
      }

      conn(:post, "/add_recipe", Poison.encode!(payload)) |> OriginSimulator.call([])

      Process.sleep 20

      conn = conn(:post, "/", "")
      conn = OriginSimulator.call(conn, [])

      assert conn.state == :sent
      assert conn.status == 200
      assert get_resp_header(conn, "content-type") == ["text/html; charset=utf-8"]
      assert conn.resp_body == "some content from origin"
    end
  end

  describe "POST page with content" do
    test "will return the simulated page" do
      payload = %{
        "body" =>   "{\"hello\":\"world\"}",
        "stages" => [%{ "at" => 0, "status" => 200, "latency" => 0}]
      }

      conn(:post, "/add_recipe", Poison.encode!(payload)) |> OriginSimulator.call([])

      Process.sleep 20

      conn = conn(:post, "/", "")
      conn = OriginSimulator.call(conn, [])

      assert conn.state == :sent
      assert conn.status == 200
      assert get_resp_header(conn, "content-type") == ["application/json; charset=utf-8"]
      assert conn.resp_body == "{\"hello\":\"world\"}"
    end
  end
end

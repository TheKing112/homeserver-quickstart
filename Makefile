.PHONY: start stop restart logs status health backup update clean

start:
	@echo "🚀 Starting all services..."
	@docker compose -f docker-compose/docker-compose.yml up -d
	@docker compose -f docker-compose/docker-compose.monitoring.yml up -d
	@docker compose -f docker-compose/docker-compose.mcp.yml up -d
	@echo "✅ All services started"

stop:
<<<<<<< HEAD
	@echo "⏸️  Stopping all services..."
	@docker compose -f docker-compose/docker-compose.yml down
=======
	@echo "STOP Stopping all services..."
	@docker compose down
>>>>>>> 12ffc10e51b5ddd256ba4dfe740324cde8144af0
	@docker compose -f docker-compose/docker-compose.monitoring.yml down
	@docker compose -f docker-compose/docker-compose.mcp.yml down
	@echo "✅ All services stopped"

restart: stop start

logs:
	@docker compose -f docker-compose/docker-compose.yml logs -f --tail=100

status:
	@echo "📊 Service Status:"
	@docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

health:
	@bash scripts/health-check.sh

backup:
	@echo "💾 Running backup..."
	@sudo bash scripts/backup.sh

update:
<<<<<<< HEAD
	@echo "⬆️  Updating all services..."
	@docker compose -f docker-compose/docker-compose.yml pull
	@docker compose -f docker-compose/docker-compose.yml up -d
	@echo "✅ Services updated"

clean:
	@echo "🧹 Cleaning up..."
=======
	@echo "UPDATING Updating all services..."
	@docker compose pull
	@docker compose up -d
	@echo "OK Services updated"

clean:
	@echo "CLEAN Cleaning up..."
>>>>>>> 12ffc10e51b5ddd256ba4dfe740324cde8144af0
	@docker system prune -af --volumes
	@echo "✅ Cleanup complete"

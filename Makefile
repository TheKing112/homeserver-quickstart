.PHONY: start stop restart logs status health backup update clean

start:
	@echo "START Starting all services..."
	@docker compose up -d
	@docker compose -f docker-compose/docker-compose.monitoring.yml up -d
	@docker compose -f docker-compose/docker-compose.mail.yml up -d
	@docker compose -f docker-compose/docker-compose.mcp.yml up -d
	@echo "OK All services started"

stop:
	@echo "â¸ï¸  Stopping all services..."
	@docker compose down
	@docker compose -f docker-compose/docker-compose.monitoring.yml down
	@docker compose -f docker-compose/docker-compose.mail.yml down
	@docker compose -f docker-compose/docker-compose.mcp.yml down
	@echo "OK All services stopped"

restart: stop start

logs:
	@docker compose logs -f --tail=100

status:
	@echo "STAT Service Status:"
	@docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

health:
	@bash scripts/health-check.sh

backup:
	@echo "STORAGE Running backup..."
	@sudo bash scripts/backup.sh

update:
	@echo "â¬†ï¸  Updating all services..."
	@docker compose pull
	@docker compose up -d
	@echo "OK Services updated"

clean:
	@echo "ðŸ§¹ Cleaning up..."
	@docker system prune -af --volumes
	@echo "OK Cleanup complete"
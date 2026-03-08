.PHONY: package-linux package-windows clean

package-linux:
	./scripts/package.sh

package-windows:
	# Note: This might require PowerShell on Windows or cross-compilation setup
	pwsh ./scripts/package.ps1

clean:
	rm -rf dist/
	cd backend && make clean
	cd frontend && flutter clean

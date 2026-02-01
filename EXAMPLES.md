# Real-World Examples for `in`

This document contains 50+ real-world examples of using `in` to manage microservices, multi-repo setups, and directory groups.

## Git Operations

1. **Check status across all repos**
   ```bash
   in * git status -s
   ```
   *Quickly see which microservices have uncommitted changes.*

2. **Pull latest changes everywhere**
   ```bash
   in -P 4 * git pull origin main
   ```
   *Update all repos in parallel (4 at a time).*

3. **Checkout a specific branch if it exists**
   ```bash
   in * "git checkout feature/login || git checkout main"
   ```
   *Try to switch to feature branch, fallback to main.*

4. **Create a new release branch**
   ```bash
   in services/* git checkout -b release/v2.0
   ```

5. **Prune deleted remote branches**
   ```bash
   in * git fetch -p
   ```

6. **See last commit in every repo**
   ```bash
   in * "git log -1 --format='%h %s'"
   ```

7. **Stash changes across all services**
   ```bash
   in services/* git stash
   ```

8. **Discard all local changes (Danger!)**
   ```bash
   in * git reset --hard HEAD
   ```

9. **Tag a release across multiple packages**
   ```bash
   in packages/* git tag v1.0.0
   ```

10. **Push tags**
    ```bash
    in packages/* git push origin v1.0.0
    ```

## Node.js / JavaScript

11. **Install dependencies (clean install)**
    ```bash
    in -P 4 packages/* npm ci
    ```

12. **Update a specific package everywhere**
    ```bash
    in * "pnpm update lodash"
    ```

13. **Run tests for a specific scope**
    ```bash
    in packages/* npm test
    ```

14. **Check for outdated dependencies**
    ```bash
    in services/* npm outdated
    ```

15. **Audit for vulnerabilities**
    ```bash
    in * npm audit --production
    ```

16. **Build all frontend apps**
    ```bash
    in apps/web-* npm run build
    ```

17. **Remove node_modules (Fresh start)**
    ```bash
    in * "rm -rf node_modules package-lock.json"
    ```

18. **Initialize new projects**
    ```bash
    in * npm init -y
    ```

19. **Run a custom script if it exists**
    ```bash
    in * "npm run lint || echo 'No lint script found'"
    ```

20. **Upgrade interactive (using shell features)**
    ```bash
    in * "ncu -u && npm install"
    ```

## Docker & Microservices

21. **Build all Docker images**
    ```bash
    in -P 2 services/* docker build -t my-app/service .
    ```
    *Note: This builds them all with the SAME tag name, usually you want dynamic tags.*

22. **Docker build with dynamic directory name**
    ```bash
    in services/* "docker build -t app/\$(basename \$PWD) ."
    ```
    *Uses shell expansion to tag image with directory name.*

23. **Stop specific containers**
    ```bash
    in services/auth,services/user docker-compose down
    ```

24. **Restart services**
    ```bash
    in * "docker-compose restart app"
    ```

25. **View logs tail**
    ```bash
    in services/* "tail -n 10 logs/service.log"
    ```

26. **Clean up Docker artifacts**
    ```bash
    in * docker system prune -f
    ```

## File Management & Cleanup

27. **Delete temporary files**
    ```bash
    in * "rm -rf dist/ .cache/ tmp/"
    ```

28. **Find large files**
    ```bash
    in * "find . -type f -size +100M"
    ```

29. **Count lines of code**
    ```bash
    in src/* "wc -l *.ts"
    ```

30. **Replace string in files (Sed)**
    ```bash
    in * "sed -i 's/foo/bar/g' config.yaml"
    ```

31. **Rename a config file**
    ```bash
    in * "mv config.local.json config.json"
    ```

32. **Create missing directories**
    ```bash
    in * mkdir -p .github/workflows
    ```

33. **Copy a standard file to all repos**
    ```bash
    in * cp ~/templates/LICENSE .
    ```

## System & Diagnostics

34. **Check disk usage of directories**
    ```bash
    in * du -sh .
    ```

35. **Check active ports (Mac/Linux)**
    ```bash
    in * "lsof -i -P | grep LISTEN"
    ```

36. **Verify standard file existence**
    ```bash
    in * "[ -f README.md ] && echo 'OK' || echo 'Missing README'"
    ```

37. **Print current version from package.json**
    ```bash
    in * "jq .version package.json"
    ```

38. **Check python version**
    ```bash
    in services/* python --version
    ```

## Advanced Scripting

39. **Chain multiple failures**
    ```bash
    in * "lint || echo 'Lint failed' >> errors.log"
    ```

40. **Conditional execution based on file presence**
    ```bash
    in * "if [ -f requirements.txt ]; then pip install -r requirements.txt; fi"
    ```

41. **Run a local script in remote directories**
    ```bash
    in services/* ~/scripts/health-check.sh
    ```

42. **Grep across multiple repos**
    ```bash
    in * "grep -r 'TODO' src/ | head -n 5"
    ```

43. **Generate a report**
    ```bash
    in * "echo \"\$(basename \$PWD): \$(git rev-parse HEAD)\" >> ~/report.txt"
    ```

44. **Export ENV vars per command**
    ```bash
    in * "NODE_ENV=production npm run build"
    ```

## Python

45. **Install requirements**
    ```bash
    in services/* pip install -r requirements.txt
    ```

46. **Format code**
    ```bash
    in * black .
    ```

47. **Run Pytest**
    ```bash
    in -P 4 * pytest
    ```

## Terraform / Infrastructure

48. **Format TF files**
    ```bash
    in infra/* terraform fmt
    ```

49. **Validate configurations**
    ```bash
    in infra/* terraform validate
    ```

50. **Plan changes**
    ```bash
    in infra/stacks/* "terraform plan -out=tfplan"
    ```

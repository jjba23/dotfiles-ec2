COLOR_GREEN=\033[0;32m
COLOR_RED=\033[0;31m
COLOR_BLUE=\033[0;34m
COLOR_GRAY=\033[0;90m
END_COLOR=\033[0m


log-info:
	@printf "\n$(COLOR_GRAY)[INFO][$(shell date +"%Y-%m-%dT%H:%M:%S%z")]$(END_COLOR)$(COLOR_GREEN) $(MSG) $(END_COLOR)\n"
log-error:
	@printf "\n$(COLOR_GRAY)[ERROR][$(shell date +"%Y-%m-%dT%H:%M:%S%z")]$(END_COLOR)$(COLOR_RED) $(MSG) $(END_COLOR)\n"

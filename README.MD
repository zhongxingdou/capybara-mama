# Capybara-mama
help you using capybara and rspec test non-rails project

## How to use?
目前需要你将所有文件作为测试项目的基础，未来将打包成独立的gem包发布，请关注

## Futures
* 在一组test case中自动切换多个会话，在test case说明后直接标记会话名即可
* 根据配置使用相应的账号自动登录会话
* 支持将test case标记通过有界面测试端测试还是无界面端测试
* 根据命名惯例，自动include放在指定目录的测试helper到test case中
* 根据命名惯例，自动加载测试数据，并注入test case实例的实例变量@data中，通过@data.name即可访问

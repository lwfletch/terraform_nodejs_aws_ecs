const express = require('express');
const app = express();
app.use(express.json());

app.get('/', (req, res) => {
   res.send('App A NodeJS API on ECS using terraform')
})

app.get('/healthcheck', (req, res) => {
    res.send('API is alive and well.');
});

const port = process.env.PORT || 8081;
app.listen(port, () => console.log(`Listening on port ${port}..`));
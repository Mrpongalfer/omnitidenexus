const express = require('express');
const app = express();
const port = process.env.PORT || 8081;

app.get('/', (req, res) => {
  res.send('Mr. Meeseeks is ready for tasks!');
});

app.listen(port, () => {
  console.log(`Mr. Meeseeks is running on port ${port}`);
});

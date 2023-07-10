// INSTA  PROFILE INFO API
// API_KEY='afe6a2ea7fmsha6a3352836319dfp14c173jsnf57566d31722'
const axios = require('axios');
const express=require("express")
const app=express()
app.use(express.json())

async function getInstaProfileInfo(username){

try {
    const options = {
        method: 'GET',
        url: 'https://instagram130.p.rapidapi.com/account-info',
        params: {
          username: username
        },
        headers: {
          'X-RapidAPI-Key': process.env.API_KEY,
          'X-RapidAPI-Host': 'instagram130.p.rapidapi.com'
        }
      };
	const response = await axios.request(options);
	return response.data
} catch (error) {
	console.error(error);
}
}
app.get("/user/:userid",async(req,res)=>{
    const info=await getInstaProfileInfo(req.params.userid)
    res.json(info)
})
app.listen(8080,()=>{
    console.log("server started")
})


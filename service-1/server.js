const express=require("express")
const axios=require("axios")
const app=express()
app.use(express.json())
const API_KEY=process.env.API_KEY || "2dc3d361"
async function getMovieInfo(title){
    const response=await axios.get("http://www.omdbapi.com/",{params:{apikey:API_KEY,t:title},headers:{'Content-Type':'application/json'}})
   return response.data
}
app.get("/movies/:title",async(req,res)=>{
    const info=await getMovieInfo(req.params.title)
res.json(info)
})
app.listen(8080,()=>{
    console.log("server started")
})